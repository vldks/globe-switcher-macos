import AppKit
import Carbon
import Darwin

@_silgen_name("TISGetFnUsageType")
func TISGetFnUsageType() -> Int32

@_silgen_name("TISUpdateFnUsageType")
func TISUpdateFnUsageType(_ usageType: Int32)

@_silgen_name("_InvalidateAllSelectedInputSourceState")
func InvalidateAllSelectedInputSourceState()

@_silgen_name("_CreateFlattenedInputSource")
func CreateFlattenedInputSource(
    _ source: TISInputSource,
    _ outDict: UnsafeMutablePointer<Unmanaged<CFDictionary>?>
) -> UInt8

@_silgen_name("CFMessagePortCreatePerProcessRemote")
func CFMessagePortCreatePerProcessRemote(
    _ allocator: CFAllocator?,
    _ name: CFString,
    _ pid: pid_t
) -> Unmanaged<CFMessagePort>?

@_silgen_name("GetProcessPID")
func GetProcessPID(
    _ psn: UnsafePointer<ProcessSerialNumber>,
    _ pid: UnsafeMutablePointer<pid_t>
) -> OSStatus

typealias SLPSGetKeyFocusProcessFunc = @convention(c) (
    UnsafeMutablePointer<ProcessSerialNumber>,
    UnsafeMutablePointer<UInt8>
) -> OSStatus

@main
struct GlobeSwitcher {
    static var globeDownTimestamp: TimeInterval = 0
    static var isGlobeCandidate = false
    static var activityToken: NSObjectProtocol?
    static var pendingSourceID: String?
    static var pendingSourceTimestamp: TimeInterval = 0

    static let slpsGetKeyFocusProcess: SLPSGetKeyFocusProcessFunc? = {
        guard let handle = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", RTLD_LAZY),
              let sym = dlsym(handle, "SLPSGetKeyFocusProcess") else {
            return nil
        }
        return unsafeBitCast(sym, to: SLPSGetKeyFocusProcessFunc.self)
    }()

    static func main() {
        let args = CommandLine.arguments
        if args.count > 1 {
            switch args[1] {
            case "--get-fn":
                print(TISGetFnUsageType())
                return
            case "--set-fn":
                if args.count > 2, let val = Int32(args[2]) {
                    TISUpdateFnUsageType(val)
                }
                return
            case "--notify-fn-change":
                let val = CFPreferencesGetAppIntegerValue("AppleFnUsageType" as CFString, "com.apple.HIToolbox" as CFString, nil)
                TISUpdateFnUsageType(Int32(val))
                return
            default:
                break
            }
        }

        // Запрещаем App Nap для мгновенного отклика после долгого простоя, не препятствуя сну Mac
        activityToken = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiatedAllowingIdleSystemSleep, .latencyCritical],
            reason: "Instant Globe key language switching"
        )

        let app = NSApplication.shared
        app.setActivationPolicy(.prohibited)

        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String),
            object: nil,
            queue: .main
        ) { _ in
            pendingSourceID = nil
            InvalidateAllSelectedInputSourceState()
        }

        NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let isGlobeDown = flags.contains(.function)
            // Не включаем .capsLock в маску других модификаторов, чтобы 🌐 Globe работал
            // и при активном режиме ВЕРХНЕГО РЕГИСТРА (Caps Lock ON).
            let otherModifiers: NSEvent.ModifierFlags = [.command, .option, .control, .shift]
            let hasOtherModifiers = !flags.intersection(otherModifiers).isEmpty

            // keyCode 63 (0x3F) = kVK_Function (🌐 Globe / Fn).
            // Нажатие любого другого модификатора (включая сам Caps Lock keyCode 57) во время удержания отменяет переключение.
            guard event.keyCode == 63 else {
                isGlobeCandidate = false
                return
            }

            if isGlobeDown && !hasOtherModifiers {
                globeDownTimestamp = event.timestamp
                isGlobeCandidate = true
            } else if !isGlobeDown && isGlobeCandidate {
                isGlobeCandidate = false
                let heldDuration = event.timestamp - globeDownTimestamp
                let timeSinceGlobeDown = ProcessInfo.processInfo.systemUptime - globeDownTimestamp

                // Проверяем по единому монотонному таймеру WindowServer, нажимались ли
                // клавиши (например, Delete для Forward Delete) или кнопки мыши ПОСЛЕ нажатия 🌐 Globe.
                let sinceLastKeyDown = CGEventSource.secondsSinceLastEventType(
                    .combinedSessionState,
                    eventType: .keyDown
                )
                let sinceLastLeftClick = CGEventSource.secondsSinceLastEventType(
                    .combinedSessionState,
                    eventType: .leftMouseDown
                )
                let sinceLastRightClick = CGEventSource.secondsSinceLastEventType(
                    .combinedSessionState,
                    eventType: .rightMouseDown
                )

                let clockSkewTolerance: TimeInterval = 0.002
                if heldDuration > 0 &&
                   heldDuration < 0.45 &&
                   sinceLastKeyDown + clockSkewTolerance >= timeSinceGlobeDown &&
                   sinceLastLeftClick + clockSkewTolerance >= timeSinceGlobeDown &&
                   sinceLastRightClick + clockSkewTolerance >= timeSinceGlobeDown {
                    autoreleasepool {
                        selectNextInputSource()
                    }
                }
            } else {
                isGlobeCandidate = false
            }
        }

        app.run()
    }

    static func selectNextInputSource() {
        // Сбрасываем локальный кэш HIToolbox перед чтением текущего источника ввода,
        // чтобы гарантированно прочитать актуальное состояние после внешних переключений (Caps Lock / строка меню).
        InvalidateAllSelectedInputSourceState()

        let filter: CFDictionary = [
            kTISPropertyInputSourceCategory as String: kTISCategoryKeyboardInputSource as String,
            kTISPropertyInputSourceIsSelectCapable as String: true,
            kTISPropertyInputSourceIsEnabled as String: true
        ] as CFDictionary

        guard let listRef = TISCreateInputSourceList(filter, false)?.takeRetainedValue(),
              let allSources = listRef as? [TISInputSource] else {
            return
        }

        // Оставляем только раскладки клавиатуры и основные режимы ввода (исключаем палитры эмодзи/символов)
        let selectableSources = allSources.filter { source in
            let type = inputSourceProperty(source, kTISPropertyInputSourceType)
            return type == (kTISTypeKeyboardLayout as String) ||
                   type == (kTISTypeKeyboardInputMethodWithoutModes as String) ||
                   type == (kTISTypeKeyboardInputMode as String)
        }

        guard selectableSources.count > 1,
              let currentRef = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            return
        }

        let now = ProcessInfo.processInfo.systemUptime
        let currentID: String
        if let pending = pendingSourceID, now - pendingSourceTimestamp < 0.25 {
            currentID = pending
        } else {
            currentID = inputSourceProperty(currentRef, kTISPropertyInputSourceID)
        }

        let nextSource: TISInputSource
        if let index = selectableSources.firstIndex(where: { inputSourceProperty($0, kTISPropertyInputSourceID) == currentID }) {
            nextSource = selectableSources[(index + 1) % selectableSources.count]
        } else {
            nextSource = selectableSources[0]
        }

        let nextID = inputSourceProperty(nextSource, kTISPropertyInputSourceID)
        pendingSourceID = nextID
        pendingSourceTimestamp = now

        // Делегируем переключение напрямую активному процессу с клавиатурным фокусом (KeyFocus Process)
        // через его Mach-порт com.apple.tsm.portname (сообщение kTSMMessageSetInputSourceSelected = 7),
        // как это делает системный TextInputMenuAgent.
        // Вызов TISSelectInputSource из фонового процесса-демона сначала перезаписывает CFPreferences,
        // из-за чего в целевом приложении возникает состояние гонки (IPC race condition) между Mach-сообщением 7
        // и асинхронным уведомлением distnoted ('issc'): целевое приложение видит, что новая раскладка уже
        // помечена выбранной в CFPreferences, пропускает инвалидацию локального кэша gCurrentSelectedInputSource,
        // и плавающий индикатор у текстового курсора (ShowSourceIndicator) отрисовывает предыдущий (противоположный) язык.
        if !selectInputSourceInKeyFocusProcess(nextSource) {
            pendingSourceID = nil
            TISSelectInputSource(nextSource)
        }
    }

    static func selectInputSourceInKeyFocusProcess(_ source: TISInputSource) -> Bool {
        guard let pid = keyFocusProcessPID(), pid > 0, pid != getpid() else {
            return false
        }

        var flatUnmanaged: Unmanaged<CFDictionary>?
        guard CreateFlattenedInputSource(source, &flatUnmanaged) != 0,
              let flatDict = flatUnmanaged?.takeRetainedValue() else {
            return false
        }

        let payload: CFDictionary = [
            "tsmInputSourceSelectedInpSrcKey" as CFString: flatDict
        ] as CFDictionary

        guard let data = CFPropertyListCreateData(
            kCFAllocatorDefault,
            payload,
            .binaryFormat_v1_0,
            0,
            nil
        )?.takeRetainedValue() else {
            return false
        }

        guard let port = CFMessagePortCreatePerProcessRemote(
            kCFAllocatorDefault,
            "com.apple.tsm.portname" as CFString,
            pid
        )?.takeRetainedValue() else {
            return false
        }

        let status = CFMessagePortSendRequest(port, 7, data, 0.0, 0.0, nil, nil)
        CFMessagePortInvalidate(port)
        return status == kCFMessagePortSuccess
    }

    static func keyFocusProcessPID() -> pid_t? {
        if let getKeyFocus = slpsGetKeyFocusProcess {
            var psn = ProcessSerialNumber(highLongOfPSN: 0, lowLongOfPSN: 0)
            var outFlag: UInt8 = 0
            if getKeyFocus(&psn, &outFlag) == noErr {
                var pid: pid_t = 0
                if GetProcessPID(&psn, &pid) == noErr, pid > 0 {
                    return pid
                }
            }
        }
        return NSWorkspace.shared.frontmostApplication?.processIdentifier
    }

    static func inputSourceProperty(_ source: TISInputSource, _ key: CFString) -> String {
        guard let ptr = TISGetInputSourceProperty(source, key) else { return "" }
        return Unmanaged<CFString>.fromOpaque(ptr).takeUnretainedValue() as String
    }
}
