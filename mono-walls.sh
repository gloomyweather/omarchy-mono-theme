#!/bin/bash
# Usage: mono-walls.sh <outdir> — redraws all six mono wallpapers (ImageMagick 7)
set -e
OUT=${1:?usage: mono-walls.sh <outdir>}; mkdir -p "$OUT"
W=1920; H=1080; BG='#161616'; TMP=$(mktemp -d)

grain() {
  magick "$1" \( -size ${W}x${H} xc:gray50 -seed 7 +noise Gaussian -colorspace gray -evaluate multiply 0.04 \) -compose plus -composite -level 3%,100% "$1"
}
# light <cx> <cy> <rx> <ry> <strength> <out>: soft gray light blended into BG
light() {
  magick -size ${W}x${H} xc:"$BG" xc:'#9a9a9a' \
    \( -size ${W}x${H} -define gradient:center=$1,$2 -define gradient:radii=$3,$4 radial-gradient:white-black -evaluate pow 1.8 -evaluate multiply $5 \) \
    -composite "$6"
}

# 1 — light: a soft glow from the bottom-right corner
light 1820 1120 1300 900 0.45 "$OUT/1-light.png"; grain "$OUT/1-light.png"

# 2 — rings: thin concentric circles around an off-center point
light 1380 700 1100 800 0.25 $TMP/b.png
args=(); for r in $(seq 60 46 1400); do a=$(awk -v r=$r 'BEGIN{printf "%.3f", 0.32*(1-r/1500)+0.03}');
  args+=(-stroke "rgba(255,255,255,$a)" -draw "circle 1380,700 $((1380+r)),700"); done
magick $TMP/b.png -fill none -strokewidth 1 "${args[@]}" "$OUT/2-rings.png"; grain "$OUT/2-rings.png"

# 3 — grid: small crosses on a 48px grid, fading toward the top-left
light 1700 980 1200 800 0.3 $TMP/b.png
magick -size ${W}x${H} xc:none -stroke '#9a9a9a' -strokewidth 1 \
  -draw "$(for x in $(seq 48 48 1872); do for y in $(seq 36 48 1044); do echo "line $((x-3)),$y $((x+3)),$y line $x,$((y-3)) $x,$((y+3))"; done; done)" $TMP/g.png
magick -size ${W}x${H} -define gradient:angle=135 gradient:'gray(8%)'-white -evaluate pow 1.3 $TMP/m.png
magick $TMP/g.png \( +clone -alpha extract $TMP/m.png -compose multiply -composite \) -alpha off -compose copy_opacity -composite $TMP/g2.png
magick $TMP/b.png $TMP/g2.png -compose over -composite "$OUT/3-grid.png"; grain "$OUT/3-grid.png"

# 4 — contours: stacked sine waves like a topographic map
light 960 1180 1400 700 0.3 $TMP/b.png
draw=$(awk -v W=$W 'BEGIN{for(i=0;i<34;i++){y0=180+i*26; a=0.04+0.22*(i/33); printf "stroke rgba(255,255,255,%.3f) polyline", a;
  for(x=-10;x<=W+10;x+=12){y=y0+38*sin(x/260+i*0.23)+18*sin(x/97-i*0.4); printf " %d,%.1f", x, y} printf "\n"}}')
magick $TMP/b.png -fill none -strokewidth 1 -draw "$draw" "$OUT/4-contours.png"; grain "$OUT/4-contours.png"

# 5 — horizon: one thin line with a faint glow above it
light 960 760 1500 260 0.35 $TMP/b.png
magick $TMP/b.png -stroke 'rgba(255,255,255,0.55)' -strokewidth 1 -draw "line 0,760 $W,760" "$OUT/5-horizon.png"; grain "$OUT/5-horizon.png"

# 6 — flat: just the background with grain
magick -size ${W}x${H} xc:"$BG" "$OUT/6-flat.png"; grain "$OUT/6-flat.png"

rm -rf "$TMP"
