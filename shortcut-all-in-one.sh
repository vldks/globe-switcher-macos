#!/bin/zsh
set -euo pipefail

INSTALL_DIR="$HOME/.local/share/globe-switcher"
BIN_PATH="$INSTALL_DIR/globe-switcher"
PLIST_PATH="$HOME/Library/LaunchAgents/local.globe-switcher.plist"
STATE_FILE="$INSTALL_DIR/.original_fn_usage_type"
LABEL="local.globe-switcher"
UID_VAL=$(id -u)
ACTION="${1:-status}"

# Атомарная установка бинарника через временный файл (предотвращает конфликт vnode cs_blob в XNU на Apple Silicon)
install_binary() {
    mkdir -p "$INSTALL_DIR"
    local tmp_bin="$BIN_PATH.tmp.$$"
    echo "H4sIAAAAAAAC/+19C3hU1bX/PmdmkkkIIZAnAUl41IaXvAIEhDKTdzCEkBkCUutkMjlJxiQzYWaCBFSCVouPeg1i7UWvQn2UTG2r3KDWVg1aW661rYC1D60GtG0oVhEBMwjk/9tn75M5c/Kit73/3vt9Z33fYu21H2uvtffaa+99zpnw6/N/uxRHiEAAIjALeGgMIbeTTJpFxgOLgQ5HubWoYENBxWoyAAQyMlA5+4xUjr1gvX2Q9m2aBpw3cYzn2Q5HQNocCFfTyqtKYPLyZ4d5US3XGNmTw+EPtFT7h5T3+HImr9MQ5tXyzFxeXH97b/UNrrDQAfpZVYPNedOw+rm8Hn9gaHvzmLwXhDBvHGYeIM8f8Lk9dUPIyyxg8r4shHm1PHGAPNneJilQH2htlgbIKy9k8uar+OHl+W901wYWOqg0n1SrlXcrl3ebhh/aXi5P8gR8rQPtNRex9mYVLw4/fnQ+6pjYwAB5CVzemypevBz9at1SY01TjVZeN5eXoOIvS16zzxvwDrT3FJcXp+IvSx6dD/9AeRc0+l0YUV6/v3icTQP9Ja6YyZsjhHkyrL+0eG50e2ocbk+tdxB/XlbC5H1bCPPiCHEqR6By8q12qyNvdZnNrsQjWYQlMj4pvEGFCYOu28HldQlheYaRx83d5KyTqKlaeV3bI/2Y8sPPQ503EMFHyjvE5e3gSlFerV8UcLVm3Hb0j5uqoEszbl2Dj5tREz+lRix+/9Dy2lS8Wi9T2BW5vBpnwKm1U7XNcHnNKt4wwvpvavJ6hpJ3isvLUbUxDLNXOhzVfj8ZWr+5B1mb+wT1FjG0vPB+XVpSdk1Bfok9XDNiHpSW88KcWlY2hiKBl2weS8gCzm8eK5C5fB2mUX8bJ5B7QXuuEEgV6o2iMZ5EyhT5GNw9zLj2pAv9rqEGuu9n8ng1p8Xvm9Porp5T09pYw8sncD3u+/Dl6zKmzju1N+Xc0pxPX/+v+bwd22snyCgocyEcd88gkY6Cc08blXPTpMj+4/hcpil2ZK02Uan9ugBtrf6A1HRV7lXQy10dbrde1e72pN/GEjKbzGGV55S6q31OX+ucQh+i4I1eX4N/jrW5+Rp34KpaJWdOpeTzuxFF5uTxMi63WSWXkFzZyuHlNrpdzgBE2STfJrdL8g/WiXWwigPsICQop4bpL8/pq/Z6Bu+ClXE76lVyzcJjiYR8a1i5Xp9U6G3x1MgaDiE/os4g/UQJopkughH6KfI5m+vdLv/QvSg1VH5SNcCeWcIw/QxvS96cAXbkRMzDh0TrhzRyXmVVeyFrZ4lox6C/nby905ScoJZFCIjj8aS/fc3myH4HtlfZFZaE9m2RehhGklNC9zpFhLa9Masgapj2+W5/szPgqu/XYGD/wnD9l6ymS1E1EAPaC9uEYdqvkgLOxmHbk9jh+l9tK/XWDd//Lw3Dta++QXIF3JukPC5kYP+m4fpf0+L0BbaovOHvHD8bRt+tHgHavlzVPk54YDj913rctV5fkx2HzpIaHN3dOB77/MP4k0i+O5w+68vzItcFbV98+evCkdvibgy4PY7aRq8zoNEjcn/INQ6jh9c/5HiOH05/v7upJsKAK/n+tQ/7MY070zlP92MKV3C+HAfppy/ngv4/BLDxFOkytHcZHG/3GYTDZ1aLHRe3GjouvkrabSjzv2JoPzaVtHcbEoMiaTtiAF4aRXZViZaLF7fmdZxZnduBdqx9nnD4xFSx6cxqtN9q7LiIfPPEPWVaOVNIWwWV8xHk1IsEcvIhJ6/jxNTcJsiQZZ1Z/RJkCB0X80j7MQMJKjLk9kbW/l20l69ybYtQJzF4casVcl7ZR9vLdnUPY9fxgXYdYnYtGWCXpv1n0AfHtlO7+mUk9dv0HGTcL5IBMga153ikPfuYPfeRTPMAe74/iiTJNhHj0DaJxgE23c9sCh0EvWy7+uWE7dqO9m2QA9tC3xtE1qD2QY7avuaR5itzGNumDLTtOsgLlFk6aJ4DaaovkzvQL8+tEzvUfvmZQQiegZ5rIftAv+zkfnsLIG9PlCXUWUY6CmR7mY+eWwe5w/nolEibF4xkc9UwNlcPtDnjv7P2VHIU+0b/vWuvOtKui7FD23Vx68von7QTObaktk9Gn0dRH3fCToS6U5O70tqPgC+m5e0kdHHrQbkd5c3/bgllmMgzuM7a5fFpY+OjyGTxytgOOfdNfnNc+7lYOjcH953t60vVtmfyLaHh2v9Z1b7vNhFjaGrqdURhnqNhjxnjEINxENstqJditoTejyWfPhZF7AeeuP3I2aeeOv3AD147/Zs3/nY6qTSv41Ex+aSZXDxSJRafbxOIPQ3pzzF+1K8EpI/DPz/AWBkxHkWQ1yOXpQbrU8mip8Cz9S22y2NkiW//oYnsEsxtFcdR/yGU0/VppnX+2LWcGNuWfw15WdTmebmh+kkkVDWF/IjOkYA5EjMvHMkT2iqMoHNi6dqgc1QCm4phW1FHr6MQc17QBJvb98WSpHu4LPKENRRAWqQ+b7giuEXVr3l7Urt5OzlcIrYdiSHnT2eWkHZBsO4Hs+uMbEti8Pijlv3Hr9hz+gPY+qNYJsMNepaXV8WydXo9aH/M+iDSN2tjWcxqQay5T9FrtDVUhvQZLtPO9cpFm78odf7DGipA+jFe5xplfKzWULJgCR2YTTqpnnLdvdbQUpSf4/OzvF/HlOD3ePureTlsf9p8OKu9p0/swFniVNonllBvNAnJY/KM9WLPKHIR6fvMY7Pbsc+fmi6Q9p7vCh3dWHM4Ru6SfWCCRdaf2n4c/VE7P0Rff8L81/H+MkDtcp3U4NkYVjdJ5pOD42SaEkxQbB1rDcXGsnGX9ds4Q9aP6tWvzzOLmD57w/q8G8PthD4zuD4iubXiAz4GVI+L/fOZHDyKdJJAOnv4frCV6yW3Rd4lI/OtW7iP9cTQ9TS4n9F1uE/Ma39UNJ+sEteft2CNdBvMA9ZGW0x4bRyKIovomhNQdyi5f4whSWaszYzR5NPbJhB7Uml+h+Jvv49h4/cW6PaXLDvrP958dJuYd3o62bG7JJ10+tO7n/vM1PPcWxO6n63/2LKTbCftZmJZkvF9srEqntgzDpCNkxOJfYWRfDoTsrNAu1PQB/SMMZL2lVhjM5MtOQ0HyZptXyIbzSi755YZDz16cNbJvcnEvkuY2VALmoz6ZhP5dO+lPnsHIUmVWEMpWEOKnj/kegZBZb+yJstrja6vR8WUk5ON0IEknkQ8ttP6e1APZ8wk93uWnWe+SzrunETGrYDOllGoB533jiH2Q8mkk/ZZNZbpewLzNV2w7NfqXJ8Q1llIYDr/bEykzjehLwt0JtBZPVfJqrVPfePMH6MXyfofZPp3xTIb/svc76uwLYWVRbH48YpZWXt0/06W97qkGLa+aZ6Nj80a6he3Ofdvg/+MwtyYydPjaPqN0WxMhvKPifAPOn8No/n8mYeZP7Nq/qLlsZhZGx05FkswFlmj2Ni2RQ0/tjtMYXmTTUzen42R8r4EeVYj6bSYSCeVVQwZMUmWnOmQsYLOD+b8rluyHnIcnHFSQNouTJ/5M5HJgF/IMpKoTiJrT3XR6lEshPU4RpgeT5JIPXDhS6LtFwLpeEZjvF+OIhvbjvXZ6Ty8jnmKwT5J29B6nyOdSTLfonXHI62cv3LR90ES9ouzaPfAI1VHqazM9/vsf+PtWFvWxoM6U1T5aux1/ARzKnREnlXZ+Q3XtCNTuf+ktjl6e6ZYQicQU+bCzxJOW0JEXPH2Cez75uXAv920c5Fg/sX7Imn/dkVuRw/iKdUvwcxi2kdmFmOJYcXbcpwG34MzIM2jfkmEFW+//Co5rJy9zq2zws9+Kp9dlphI0rl1LyIf56at0PM2pmNyeW4HlfUbM4uPj5mZX+8RWR//ZVb25ly0tULmq/seNA+UJaFeFeIwbbvTHN5Pz0UzeWfQF10jO1BG5zGRriFy4Qitcwz9qOVTff1GkqScif5qwFnuYctO5Rz20sW+VPWZ6YWLfQ9inCuUcvX5kPa9C3u1fNbbM04+C94NHY5x/V6LpvtB+Gw42Bid1cjYivbH+f5D5T0jy4jUv+9Vel42QU4U5LDzPN2jPkddrT51irypROb/A3XOIP2JLLcQcgs6IK99cP3EYDKxhBYRtUwxWAGZH/TrmII9PXIOt0eTpMHvHWKwOxp7MfSdDxmT6VnvXWtoCmhujzU0FdT1oTXUjbHdRfVEPUHofi5J7Hmu29D97A7sUYid7cJPLDvp3hmPuabz+yxhPnFO9oOkYJqZxcwz0M1+6ZNnt2Pf24G9onsq+oZsqi/W8RG074+zo6iPPUL9YOBdh/ZxezTbl49jnSp7ZGYU2yOPjWJ75DXjiH0GKMGeM4rGsnfJ2JLrhLFlXWSsYxb5dFZcW8U9z9yZPh3n2tnP7Egvjm6r+BXoGMTiUwJkvkI2Poa4lCFe1VANak5vq6A2ZkQJPH+2nJ81HnEL+Wb0MZ10Hcm4Q9hooPu1OKvhFRrnk9sq3DdPeWjFwekn98ZBjmgeNVPIaihE+hMT4iNi3vYLffarCNsbvhfH9Kb75/9vvfPMTG/RHKn3sah+vWfeERWpdwzmrscwKrgAsvZi31D0LeX6zoC+K7m+M7m+94DuwT4zmlDdLEveP8h0fl+YFaHz+yaB588cVOf3b0e5SMtnNFSLTOcOrrMV+8whwTxqNnT+M9oSjA/do8I6jw5GqWQZeJqVmWdkCuYg9Tcl9mvX43H4txxbsMeMln3XEJzE95qzsu8nBq+NVp4FJA+Iex9g/WVh7ZR8tPmog+SdNgt37o45e8vRFUssJ13QncrfRvJPT/9o69HpyY+mrxDIRjf6+it0LBl75+7JVnPwmSiSRHWjMajXYYBsY4c6FrkM3c8lXig/mg28Teh57pUonC0/YmdLQhLv3i4m/kKJO+fW5WMPyZPjD+Y4qf5dy87jj5EOGstoPSIk3o0zxq7B6lN7PoQ99I5C49ufMBZ0DD6Q90ZjsNdgCt6DtlUG0knvIALGeJqy3iHfeSsdz1TUTwl+iLH6E8bsz4a04GIlliTSvS8taI5m+6IB9GUx9WQmxont3SLG2BDchj4sob4DryMuwB/f9K/MDTljLaEqyF8TFTk3o1Vz8wvUV+8lKwg5md3Vttsusn3OQp8vZBroffjNyW1j2k8KOMNTnTEXv+Vyfxal3BWSgubQtqNmQTh8/xShg/pVJm1fnBtS7z99r4qHL3hNHefrojCO0RhPM8pwx98ai7kTEZ+jMHam4GTstWdhnwiaHN/73MMXyo7WA3sySChDmHjymCCfnY6ch/2GBNKRVCp0pCeQULfscyshswSyi9FHEfoq7LjgpXsMuwOF6FgkCh3bxPzTOz7eetQMP7sTNlFZiycf2k3P9PU8zvd8WezYgXuLm99bqL/2TCChHNT/AHe9yuhbsA+kB9/HvHTTeAEdT2TgLiTEnDTQuAJdX8H5dQH2kAnwRz/dRzCv2fDJCfVbc2g7erdK5PsI3RdOmciuLzCmtGwPymxi93PFLzfvvFNes3t86ULM3cmo35NqCZ2ZasQ5Smif4Gay6DmS6qPIwr626zxkJV76y7M9uHNmWDecdMt3mHCdX5lYnatTSc7LYtrJbvT56NUbTsrPUKJJ+8/ls2W4Pl33P1OdN99H+1+CPwtf7U60dnwQbQk9pDlLqv2MxgC6zqmPCRiTpGVlR11C97O5wu+eo3Hl+5BntiTdbX6xeWdVlOU/HxXJp+axbbuJcPP+GNhN6wSHrHPL/gh/M4g4A5jAIzZsjcbZlZ4BkuQzT1uKJUTX+esm+iyt7Ui6ifm07Pd7ROb3OG9MMqnPL0nwz+Rgo4mdYV4yKWct6ndF6KcQfgdfM4jt6dB16P4FOW4oOnSY2H2enWWSg7Vc/pNK3/wMrO1jKfq44H0BPi7A10XkG1COs85WxEOcHXaLQvuOWy1LEN93ZsG3F5Csu9yXCo+WbHX3Tv/S0d24gy06C32oLl8YsuTz/O+Mg4/Du0b2LGVfOs5irf7eN6FbCDzTmd5JU4NTkdcr6zs++BrSOQJZXI97ZqIw4a569Fu8tb7XjH57LkYvFqF7Gnwad6px7AxeAN3zYUMebMmFTVas25/J8zjYHeRBjW02btuJLcy2DpHaxsa5F7btgN7msYl3E5OlI4OknMwka893yXtOSpA+f6H3aSt0zuzXOU3WuWcL09l8KXoxYngF1Xsyv6MNdhcZ5Fnym+rn58pztnvQF3w3tO0W0kHT15sGPtfPSrKEMs1dy4m5bTk9bz6Gew5B3kOgdP87OdPQdGKqsSnyLI79yBS+//0a6YwLZKM1htg7Y55fbIc+8rsTV+Q7hnrU2yHiLGUiG/ea5ee3b2YcMyyhMuIR5/nz7Dfld0mGyOfi15rYc/HYJVWTsqjfPGEN5SKP+gh9plXM9TljYnJov8t5m1FoQ+83VqzrC0ZWTnk6xr3gYzjvBJ4Bv2PFA0eyrn/h9L6SN06bP/rLaUGoe0Sc7pw0FUiynJOKJ1dN6vmLuH/fv//76R1fsHLLa85J1QXVk6ofcAGrJu3DuWmUie3F2JjlO6AR/BjMrWwjHx96VtoR793Zg32oP98QOY80bmyT3zmxM8KJqflNJ2fmNSlnBFr3JVPk+GWjLRv/sByzib0TGKofgvIA+vkzYqsQZwll4b4dU2Jd4ibmxaLJErKQjLcJ7klJ8A3tHZHm486wM4PgbjDecp6eIaYjL+ti1f2ZXdPvPgbfUuaSjnmVSCL27fN1P4Z/Cx3a+1Si2RLym+hezeMF4eeFqjHt7/f1Paj4YD2PKWlEaD+N9IFXSPsS2PXchm0d9DkjjSEHLvU9uNdIFpsv5B01/+nmndOndu2ObajvLRFigjENWb1s/ZK7U68lHTsmWUJCMrmbxt13cX/egfMOxu8Z+lyGyt4RS+TnBj9CX/4o8ulBnH9NmMts6vtluSHqf28a2VnoEKfqe1evw4r489o+9VlYu66pn5tD6FdADB9DQnS9KO8/Dkax9WNut4R2wHf6RpFQ3wqyhN79jq3AOVRY8XYXIQuR/yM5D7HBAj3ajCRbXj/J1pAPfCZfP5uNzFffMjI+YAyv7wYje0YsP0Mxhu+TEl1L8pzKzyMqsnDePzHGEpoB+Suh90ro7cA5ZTLG7IQhcQbBOGvjz2ejLD/C+XLj6xf77H+A38lz3IVY1td3ir6/2WRkZ4H5oMP5yP1qH2njewoZ016p8pH3DcymVPiIG/Ke/w7zEfLOto6FxvD7AdqX8t7ADJ85aIj0mb/ewHzmxA3MZ5JbM3upv6RQyv2kEDan5TE/of5x7AJ7xlZgZM9v1H4ysl+IuIcYO7T7PH/X8XS/j+Ds6oW98vuciVU75fsnxr8+3bqlYQyxn4L9GSSxgSDdhzPmsVdZfP4NzZ9IfBbcr8/gDJcUTzrf5s+vMZ5Pk0x5PJ+e3BXfLkI+jRuj+XjRdxPK+yr5PcVB9ux3OmJtlxgTpM9/cw10PJODXfFib2cKkW3+vSH8DuIuyFTeo8UY2V3kRZGdmX4psn5o+tcimxdZpyquU3li+69E5VlNqnyGofvtFIMyn6nBXxrkdypPm2+2hlIFeudh9cTxLO5hXz7ip8/I4EP974Osqf3P57v4c/EEg3L2oO3T5LPqtQZlPaQF9yINOZ3kQ+IVgPKzOfgX1Ufpx2bg74tQtsrA9oX7DczmdgN7pvNvBhYvvgnaJ5KN3amPpsfRcynydvA6UZz/Oudv5TLaDPK4VfTgjjAddkyHb0yHzSsEs/xcWH2+63Xky2c86msbaF+vRh0+MTWp6YI3GT6YgvJU1EtD/fHwuXTs/VHtVGd5/Lv4+GeOab8Za+TYVLF9h6H/XeLT5BjzCXncC6whAh2qikjnKyKd98RgW9StHXLZcla2p5B0/ljk8/RHa6j+ShKqijKwOmt4nQLSuV+kZxpTx0LkHzhnDbV8hYQWwd5NtwpL5LqreF/5pPO7cl1zR0slCW3KFeVzRi10VZ6tehRburktljHtK1F+nMc3eh7IUXynIDc0mdZ5V36G97Sr2xoSJ7NvCr4hsnMqTc+X52E8vYtX/BX5XcvYXZfKIK3WULIh/Ox0NtJVKeydZd/VJER9fKYYfvabwMfzGNa68l7xmyLzmSi6pq5GzEkmnbJ+JbmhHsh45/jNOw9duuVo/WJyoGqUJRRaLXR0p5KQJYl0ptFvYGJzd9I4IbdZaw1NxFjJaaeVxZAJvOxazidy/mucx500lEpjDWJOAjlQjz4yDOaTty4g9kPxaXeTsZbQcW5DajR55sn5xH7dYrp3JAfPGyZi3UwM4iCwaw9/1v1bMbzPXI30BaQ/48846dqn7zGxjx3AgCZNhP6J9Jk3zcsmnXNEdnehz1AfNZCTTvj3NjHp5B7cP0NYC+cMEyBnonyHpO+r6fnbKbK7L5X/c6TfIWTRF3Ld8UFq1wXcQxPo2sIdumse6UzR9LHdwPqwgmrbUZn7+fw8Te3CvC0A7cE8JcbgLi3PY2Iwm5exZ/fJwQWcp3NP78N94viTwln27FKr/zyV/g8iffX56MXduA+T2aSTPj85Lt+zmK4H5fGYcJJ+K0HX3GcYj6PyvVqROUGWOVE1B7fK+k8Itsn9RNq3K4S+oG8dyt6W5aTJ56oz6PfrMp8YnI556oW9IfhFtKz/+OBX+ZhMQ1kOfCntmlz57ETlmL+45WiGgXya8sSj6e/T90dTiH0C2m6LJp82TaHPEdLkdUj1SQRmjiWd55X1hDuAFXl0X6BnliKRrZfPROUOkBhcJsrfITwt34/4mCvn3XyU1eN+hPvK07uqje2LQT9faZX30R6RdLaIltAxA1t7ytkVl0r6ndRFgjuFkHDDJJLpnHQ7fc+N9bCIjtlJsSPFQBaez6D7THpwnmx7mqzbeNg1nj6Hgdy9GXRNpAf/grFrS2BrIUk1D5sFtoaOZbD9MpbLrrzYl03ldQgs5ij9pPJ+ZoPSdZIyKnen+TbSTtfvF+hvhWHiSQvuXClR5IAZejyKNSumELt5zER5zZ4V2L70YxPVi+5vE4K4u+7q4uv0bwJ7hkN1WyMwPdk6TZd1OI48+n0M1qo9mr1nlNcqzWPrMv1kVRSxK890aCz7AG2p/90kKHanBt/kd6Vummciix9FDHkYayL6fJ/99v71kBZcp+h7vu8AtdsKOZ8iT35uiTPoSwKLwz8R2Lhsp+9NqZ/KMtKDh3g+bfcB0ilj2bhQv62Hj/Vg/dN95IdCeH9/G+mrTeQAezbK2r4lsO85vsP13g9qlPtg5W/I+enBp0B3wBYq/47RxP5XrKmY0a/vztwb+1AlxpjaNAV16PN5+tzRjLGjfkjn/Fun+hY2Yn11xfU+R3XMIIi3ccQu69ha1XuHSsfvcz22K/6DeSxD+hzGRIm5W4TwGeQ9Evl+sZnb4wE1yXYkBxuQVt43fo7Yu56u4anG9q+CbnUZ2wniT6KNdPhR75iLrpcJ/WuMtq03kItUTtnFvgfhH4tp/YxtpKNOYGeX6Zyu4X2vFthZZhWfw2v4GH4VNImwZ/NqfF8kn3btf2j3h7Al/xKPS4TFSRpHPvpjnxxHaqkcjMNiLnehQJ+HbMD55lqcc9bjvLMO557Kjgvetbhj23G/jmpXzuF0b6Zz9CM+XnQetw7xPnsoVGJZEffTTBrD2oR2+tx+sPeu8tnEws8m3fHtUy/IZ++gGfdys4mu+0T5nXW35vs8K63fZmifAppbZWqfQL8/oHlVPG+PsT2FDH6HJwI5IPtCRlvFx+ysL+818dC56tKjhwb0Y+Eyu+V7eRJ9Vp8JOVXyt4CD2UX9zByk71g/w1hCxgGtXG19qoMYZwlVx+MOTG0XhrZd9R1gxB3hNdiivN+OqLPHwOqcGtv+E1WdpV/0pX4FmH62L3UuyhPuwLlSzHhbTt+lSj+SG05/R5V+UpW+V1V/pyr9LVX6Z6r066r0r1TpI6r026r0H1Tpj1Xp06r0blX6vCp9SZUWVTpHqdKxqnS8Kj1OlU5RpdNV6Umq9BRV+ipVeqkq/RVVOleVrlXpeYMq7VGlfar0JlX6VlU6XZWepEpPUaWvVKVnqNJXqdLzVek/W8Lpv6rSi1R1lqrS51R1gv359yX8QJW+ZAmnRVV+lCodq0o/q0q/oEq/pEq/okpX5IbTlar0BlX6elW6WpWuVaVvUKU9qrRPld6kSm9RpW9RpW9Vpe9Qpe9Spe9VpXeq0t9SpXeztPL7Byv9DhjxSC7bz+xXx2S53DhCuXmE8rgRyhNGKE8aoTxthPKJI5RnjlA+bYTyrBHKZ41QPneE8uwRynNGKF82dDn/geaA3+uKmt8GR3F6GgUxoE1Ot4cUNXqrJduN7oCrXvKxctxtSSLoxyL7bd4Z0LGgl0BH09/FGZgsSulvcc0GVs/hyJPb20tsJZ7mloDN2+JzSaQskq+QaolN/bNwkleY73bR3/I5fa2kTM0NrMvq29iflyhTUkq9AT/NJBeXETLNoPyM20CKDWx8/ob83/2hr08ZrYdvIuQY8nrFcN2JvO5h5C8QwyN7CnVfQ94bqrqnRPab6QPIHyMy+vDv+/oofZPTBFV/s24Oz0uJxx9wegKZ8lRkNkitmY1OT12Ls07K9MsTE/5TGjLMnu3xBty1rbNrPbNd9agqRY4P/Y2tVOhZ64cE+us27fi5vE1XOWmdq4pL7F5vY7V3c0R5wN+kmi+b1Ci5AlINsmw+1zVSq6o9al7V7PUF5D+zEP59m+b3qOU+9yZnQFL9LNXW0FrqrqtX/xBZyUJ7W2m5rUgKoKtCr6vFX+7zuiT1D9g3zVtkWTHXMqXMVkbHgf+ceErOwPKCTZIngALxl8sJaW1tLiLCv8kr40XKC6PoHxMQfkNNRslF6sLCzymHGvfLNU7QSe/EP0VEvJPm2GyO1mbUZhT1GlgulS3W0bTYupxWJ33R68/R+e6LDsgUYn/b16f+mVzbhb6+NdSf+vr6WpF+60xfX+cgf4NiH8oSsOJovceRbjzL5A0HtH4Xr99z5vLq38frP34Z9RW4F/WfuqTUZ3/x4x7kdQLfBWZCZj6wGfgwEN6d562RiLOmZnW1X/JtknyFXl8ZvGCpV/496dKNLVKLtLTFD6fPbfS6GpYSf73TJ9Wso57T7HTJbelScTau8nrcAS8VIE+0f5WTLZZVTn/DUiyMmkbJt5T4WjykWqpze6z016ruQOs6d6B+dTP1Gf9Sn+T0ez1LSY1U62xpDORBDMJgrc/rCTR5/QHVz9XlcLmGKkeavDXyj0ULG511ftLM/DP8G9L+HPrnQvxSQO5XllHuhbRWxSK1cL+8ZNZCK6wk+g9CQlMzixYT+d/cWKb8vRGVfwgs7IiIJcZoljaOAWYA6d8lquK/GX9iOf/bPZr5M8izVkSyBEP/DJbSv2UC/B3/Bfg0dFIP3AfEHZ88D7wALIYSO4C7gB8Cl0HETQb29zwO0RdA0MZuJKZ7QN8AxpmI+fE4YiweTcTS0cTQC3phNDElxRMxLR52xhNTdjwRmuOJ4XnQhDHEkJNAxD3jiOHUOCIuSyTGtiQinEoi0T0pRKhKJYb8NBKdNZ4Y3xpPhMx0QrKBy9JJTA4GbT1w30QS9dQVRHhjEon6aQYxzppCYh+eCTuAZ4DmWegXeB2wGdgJPAVMmk1IDnAZ0AKMFogRQ2TMEIb900c66KCDDjrooIMOOuiggw466KCDDjrooIMOOuiggw466KCDDjrooIMOOuiggw466KCDDjrooIMOOuiggw466KCDDv8nYS6nbfQ/xiUJZBen9P9rD5eGU99ezsof5rRZrpepkZrZpvwYbmKRXE/4V9spcL0MXK98WS/LZdcP/J31Hy+KHD8FWHFCm4FTI6cmTqM4jebUzGkMp7HK+FJtoo1Ro3h+HKejOY3ndAynCZyO5XQcp4mcJnGazGkKp6mcpnE6ntN0TidwOpHTKzidxGkGp5mcTuZ0CqdTOZ3G6Zc4vZLTL3Oaxel0TmdwOpPTWZzO5vQqTudwOpfTeZzO53QBp9mcLuR0EaeLOc3hdAmnSzm9mtNlnC7n9CucruDUwqmV01xO8zjN57SA00JOizgt5rSE05WcXsNpKaerOC3jdDWn5Zyu4bSCUxundk7XclrJ6TpO13N6LacbOP0qp9dx+jVOr+fUwWkVp05Oqzl1cVrDqcRpLad1nNZz6ub0Bk4bOG3ktIlTD6deTps53cipj1M/pwFOWzjdxOmNnG7mtJXTLZxu5eFT30l00EEHHXTQQQcddNBBBx100EEHHXTQQQcddNBBBx100EEHHXTQQQcddNBBBx100EEHHXTQQQcddNBBBx100EEHHXTQQQcddPhHoFz+QXECSeL0Nk4f53Q/p3Gc/pzTw5y+z+mnnG7j9CKn40oYtXB+Gufnlehjr4MOOuiggw466KCDDjrooIMOOuiggw466KCDDjrooIMOOuiggw466KCDDjrooIMOOuiggw466KCDDjrooIMOOuiggw466KCDDjrooIMOasgE0v9Xe71IyE1E+T/sGZhUafp/v89VpYklKuJ/vBZIQji/S51PSAxkx4wDTgHOJyT2euAjSH8IPAM0CyQmGxgQiPA88AjwNDBTJEIusBZ4D/BhYBD4gkjEt4BxBiLmGIih0UCMdwHfBBqNxDgDWAW8B/g88DQw10SMXwd2A6dEEeN64MPAj4BXRhPjZuAPoonpPWCWmZg2AO8Fvgk0xhDT3BgStSGGRAeB9bGgwMxRJPoe4LQ4Ev0WcO5oEu0ZTcxPAv8ATIgn5lnAlcBaYFs8iTkEnDSGxGwAvgC8MoHEPAk0jyUxKcBZwFzgPcC4cSTmK8BS4A+AvcD8RBKzH5iQRGL2AC8BH08mMWUpJOZhYHwqiSkE7gBa0tAPcBPwV8Co8SRmGXAl8CbgT4DHgbHpJGYusBa4G3gEeIbmTUA9YBD4O+ApYPxE5ANLgY3A3cAjE0ms+QoSWw989wpCHNP8rYF1lZTmrmbUtmZVM6PzJcnrbrVVb3ZsDhRusG+kufOy87w+qdDb4qlxBtxezxJHXuHq6hskV4C1Grq83FZsr5YFF/MOim1rlJwl9U5/faWzsUWyuTfVsa5sxdk0N9vtCXhb/YuKkZZ8lVscgUKlfN4Ch895Y7HSNNsvSTW2+W5ew5Hb6HU1OFze5tZ+xic1Sk6/BL7Mluf1uHxSQLIFnK4GuRjZDld9gz/Q4Khx+m50e2iGnxbTbEet090YmVPX4vTVEEdNo7dZ8lDqb20ijjop0OxGdpOzEVIdfvcWdLg6d2WeI6/UarM5pqFza3Nzo9slD9GAsoJNkicwIHed19fgb3a6IKtICpT7vC7J7y8vyScOewlsaW7Na/H50PAaqbXaC7VKPM0tAZu3xUdb0Co+yRmQVLmlbn9ALoG4Qs9av7NOsrc2S0qWqiY6a5Z8gVa5yIYhdAW00tc2Y76lCDEO1mNhozMQkDxSpEKOEs8mZ6ObNrI2NjKZEVUwKwHUa6CaI1Xn9bUOahmtUOYNuGtbFSGDVMurd3rqpBpWW7FGXc57GLICHeahivwFHmd14zDSS/xMtTxnM604ZD02bLSQpiLMWCUF6r0169z4F4y3RvIPVRFlA4tKna1oR7AWV8FpMEPlXl+ATU+55OO+VCE1eemQR1QKT5OmwCZ5aiqkjS2SX5Zb7pNqJbgfBMF34N0lHgwp1itdmKwCs5d6Hes53xlwDlwXPp+TTkNeoZUuHmfA68uXap0tjbSXInllcP+QXF5Pjd/mRpelTn9ALmIjiCg0NxyB5s2X3YMvtsoFixwtHtrUTVms0NZcn7umTir0eZtYoHJvkvJarXk277zsMpu6bZ6trnDDCOJXOeXQlK+uUjBviaNa7sTuDXcB+fPLbPlul6yHrzWvtVBuarucpjllNlvA5/bUDd7qMo202dSSFOtszkhZ2Y4RJTkW+SQ/5shWbfMu5pOY57A5WzcX2eq2BKhczTznww187uoWrNeIIcYkSr4BtVfDdeTyNS1Sy8Bgyh24xFPrRWTxVt/gcjhb4Dks2Jd7vY3l3uahSlr89YSVNPnrqFdzztsccPilxlrO9u8cnAs46fagYqxhuVgYgRafh/u+PDs5dELqJVeDVEOHbq29MIcOf0Wrf+FaLJWcyiI++LahNj1WmkNbVrqlGyux+dWiQ3edp8RTI21e6KzFyNlsc/PnVloLR67vyPHW1vqlQG5rfxube5BWi5VWtpZqv8vnbg7kNHv9sjcoqttsC2WRlf29LkH7eYtkAQvd2t545YgOyxixFfvXlfOkvT/pn7+w1Ov3N2KKuat6PZsQS9wIpv2VIHiza7iaFVtsduDKxQWNUhMNI/aKwJbGlto8pb3f5glrV+Ry18kF1Uw1f3hIcmrgu06EnexazOT8gNfmDo+AtYiZ5J+LKWcr1+ppZSvF7s2d29ra3Lq+EUtNrjRvXp63qcnpqSl1e6TVS5y+uhaqGpYgNCnaVLeB1ZrvkFdUbkstYmwlQgJOGIoVjd4by52B+lYq1V2Ifx12/0LWbIGDDQLrvXLeXH+90yfVUEPUjrepjlVfiMEKuOtavC1+ubvKuVj6Tc4Gaa3HjThvpfHeL/mw3LGPudzYumqxdPNhUmS3A+RAfyyrVS0BeQmPWB3ByxfZkdXvb2mCIUwRNgw53saaPESpQKuNHvhGELnY4WzGEa2Gj5osMGyX0o9j7gKPdCMsgsjNHo3QHEee1+V1ygLX+ag4X2UORMoTT0+tSrVwSLchImC7zMtxsr1MynEpFuW2bt7oKJJV3zB0w1UeuWz+AofGIm2FxQ4/9/emZswxPSjYmryNeTTiOBxLpM3NNFJ76mzV8DnuFkUtAT8cNh+u6iiat4g1dfu9ngo5lq/mjgzPDiyYX1nGGOYzvNuFzZATcCzxS2hJt+p5cxGDMFM0DU+vcdjm27gYJZQtdNBTujWXmu5ii6+/bImjFm0bcV62udm+1tqMfh3+G921gYKmZoybyviIAtXYwbRGKUDP1XKxQx58tgb6s6iYfBxdfN5WJa9aqkMQd9GNpD9LXr+saYUS/wcrYpsBK6lp9Tib3K48nElQnJfX6AwLhLtE9oCFXMjCKz264JTnrJFPRf2lNDu3dZWT2lRT5mzCAZ66grQ5MF9VC/PtgVQ7O16ybLfHHZCvNpGm49LTX8UXaRNnHZ5whtowxoVLEc7zJe7ZGHMlu8XT4PHe6Bl01DRlTPqwl0artSDyGjpy/eE20OFbRt5C5YciDjKOUhFoIBeWIeVoqndImyUXji6OeslZg+NKTBM1ZDQh3ZlxllJLnCXfYozLR6J8vYVm5Fgs3x7zuGAsrTKmGY1py4rXl74r9BjLS38qNvcaNrcJNR8KTwmlSeYLhszyr4t7xF6UnhqXUJyUZEnKXzZtmtHIntGUjyUEOpDcAqf8yIdmjxES+p/fpMk8ITdNYvwklh+tPOO5WcM/wvhYhX9Jw3+s4bOESH69ht/K+BiFv02I7O8lTXm3hqfjrOZTNPwkDZ+l4b+i4QvFyP5v0vCHNPU/0/BjDZG8VcPfqOGf0/A9Gv4TDX9ew5uMkfwMDX+Dhr/NGGnPO5ry4xo+0RTJ52j46zX8Axr+pxo+LiqSv1rD36vhP9DwsdGRfJ6Gd2j4Ng3/roY/oeE/1/BTzZH8Cg2/QcM7Nbyb8f2PW+/V8N/V8Ac1/HENf4HxUQo/LUbmDQq/gPGiwq+OiWwvxUTO//2a+h2a8kMa/kNN/UuMNyr85NhI/moNX6bh3Rp+m4Z/gPH9j66/o+H3a+r/WsN/rqkfPyqSz9Dw8zR8PuPN/f6u4VtHRc73Tg2/X+Yt/fHuHcaPUvg+xscp/JQ4me8f7yLGj1b4OsbHK/w3GD+m358Yn6DwbzB+rMJ/yvhx/et7tMwn9tvL+CSFr2Z8ssLfzfgUhd/H+FSF//noyPH7tYZ/W8O/NzrSPz8bHTl/SfGRfK6Gd2n4WzT8Hg1/SMP/ScPHj4nkp2t465hI/cvGRPrDdRq+QcO3avg7NHxwTKT/vKjhD2v4DzV8n4YfnxDJL9TwhRq+RsPfpeH3avjnNfxPNfxRDf+hhj+t4cWxGv01/EINb+BnGhoQ6aKhA0kXF3Vo6sTUcamzpvKzznhgOl33/P3YZBrjaRwFfgl4JfDL9JxA557up8CZwFnA2fw92QJgNtWF7ofAJcClNNYRdtZaTs8VdGzp+gXSP5FN/yz2SuA1wFLgKuo7ND4DK4B24Fq6vvk7OzewhZ4XgJup3wC30PMSYe/y6LnsFhovCXtVtx14K93fgV8H3k59i8YH4A7gnXQu6foF3gP8pkqPcuAarodtEB1W0HUHLBjBLsWeBmAjsAnoAXqBzcCNQB/QDwwMMXYWembhY6jMrXo+6XxZ6b5PY5Vq3DYNMlZDzf0E4ETgFfy8q/jClL/TF64CzuE+MQ84X+Mbi4CVwHX/5HlT+7p85hnkguFoUm5K/+IH2//A679/5U3u8l5M9r8B/Qee3o/wTvJy3moO/i50wDvTQV/P9r+8/de/RdCfef+ffeb9P/ICSH+Wrj9L15+l/6ufpSvf+/wv/BLgcl/va75++Ts+rOEfF/xDr6IH/zjn73lBPfR3Pf9bP+QZ9kOqf8ZXPv/Ur7H+Wx8A/LffMfE3G4WrK/IKHKWrrfmYVDkr8rg5QsWSJlVng9SBjzY7A676YapcVl8lq69xB4Ypp2+gGocpX20r9dYNV95/Ihim0hrMU2ALNXuYSjbY6x5WF2w5OKY1UR8tqcF6wcqVfP5hGqwvH04rR26LuxFx3VHb6HUON0be4frwu5uG/iBw0K+a9C/c/plfuEV8c/k/+VWP/m75/8C7ZZ+zxrd0zpyFi+ZlL8yeH/7W/fx7cV2ECPtI+F3LNP72cRd7GizsQR3KNxPRqLwBfpO+8uRpExHmlGeKJP7yvt7v/wBfqGv0VkuzoTPCueSbvRCQvSQ7e8lcKbu6dqFrXu38BQvm1c51zpu3qHbRAueCnNp5LqdrCfl2a+Z9Zd+T4ls232NauefpirIb2l7+efpjs3uPLH4yNS90x0ga/PDZWx9bfpVYWWT7N8sfsoJF5kM5047Yf/vcg8VFcbmznlj4w3uLDu5OLyw5U1lgfTFq5zv/Gf2flx5I6t6ResvSjG8cbpj4tGHBJwk/jX9kTXPle1f/4DfvnX/pkeDh656dclPF8t+/87Wd79706zWftN9Q+kalO7ElI+GJ5Dnf/82LW5YYygIv3f3ed6sSnj/7x3e+Ef9q+pU/PnJ11hOzZk1/7fipw/mnT5uD776Y/otvdn8V401HPo7NzyiaNncZf3v4cIO4+v8BfnB7oQAxAQA=" | base64 -d | gunzip > "$tmp_bin"
    chmod +x "$tmp_bin"
    /usr/bin/codesign -s - -f "$tmp_bin" >/dev/null 2>&1 || true
    mv -f "$tmp_bin" "$BIN_PATH"
}

ensure_binary_if_missing() {
    if [[ ! -x "$BIN_PATH" ]]; then
        install_binary
    fi
}

stop_agent() {
    if launchctl print "gui/$UID_VAL/$LABEL" >/dev/null 2>&1; then
        launchctl bootout "gui/$UID_VAL/$LABEL" 2>/dev/null || true
        for _ in {1..20}; do
            launchctl print "gui/$UID_VAL/$LABEL" >/dev/null 2>&1 || break
            sleep 0.05
        done
    fi
}

ensure_plist() {
    mkdir -p "$HOME/Library/LaunchAgents"
    cat > "$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>local.globe-switcher</string>
    <key>ProgramArguments</key>
    <array>
        <string>$BIN_PATH</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>ProcessType</key>
    <string>Interactive</string>
    <key>LegacyTimers</key>
    <true/>
</dict>
</plist>
EOF
}

case "$ACTION" in
    on)
        stop_agent
        install_binary
        if [[ ! -f "$STATE_FILE" ]]; then
            orig=$("$BIN_PATH" --get-fn 2>/dev/null || echo "1")
            if [[ "$orig" == "0" || -z "$orig" ]]; then orig="1"; fi
            echo "$orig" > "$STATE_FILE"
        fi
        ensure_plist
        "$BIN_PATH" --set-fn 0
        launchctl bootstrap "gui/$UID_VAL" "$PLIST_PATH"
        launchctl kickstart -kp "gui/$UID_VAL/$LABEL" >/dev/null 2>&1 || true
        echo "✅ Включено! Клавиша 🌐 Globe теперь переключает язык мгновенно без большого баннера по центру экрана (комбинация 🌐 + Delete и работа при активном Caps Lock сохранены)."
        ;;
    off)
        stop_agent
        ensure_binary_if_missing
        orig="1"
        [[ -f "$STATE_FILE" ]] && orig=$(cat "$STATE_FILE")
        [[ "$orig" == "0" || -z "$orig" ]] && orig="1"
        "$BIN_PATH" --set-fn "$orig"
        echo "⏸️ Выключено. Возвращено стандартное поведение клавиши 🌐 Globe (AppleFnUsageType=$orig)."
        ;;
    status)
        ensure_binary_if_missing
        fn_val=$("$BIN_PATH" --get-fn 2>/dev/null || echo "1")
        if launchctl print "gui/$UID_VAL/$LABEL" >/dev/null 2>&1; then
            echo "🟢 Статус: АКТИВЕН (работает в фоне, автозапуск включён).
Активный режим HIToolbox (TISGetFnUsageType) = $fn_val (большой баннер отключён)."
        else
            echo "⚪️ Статус: ВЫКЛЮЧЕН.
Активный режим HIToolbox (TISGetFnUsageType) = $fn_val."
        fi
        ;;
    uninstall)
        stop_agent
        ensure_binary_if_missing
        orig="1"
        [[ -f "$STATE_FILE" ]] && orig=$(cat "$STATE_FILE")
        [[ "$orig" == "0" || -z "$orig" ]] && orig="1"
        rm -f "$PLIST_PATH"
        "$BIN_PATH" --set-fn "$orig"
        rm -rf "$INSTALL_DIR"
        echo "🧹 Полный хирургический откат завершён! Все файлы удалены, возвращена заводская настройка (AppleFnUsageType=$orig)."
        ;;
esac
