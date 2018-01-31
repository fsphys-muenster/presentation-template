#!/bin/sh
# Generates a complete .zip file with templates in German and English as well
# as all example presentations (all possible combinations of color and title
# image).
# Note: This takes quite a long time due to the amount of processed TeX
# documents.
# Command line arguments:
# $1: the LaTeX engine used for compilation (lualatex or xelatex);
#     optional (default: lualatex)

texdir=tex
fontdir=tex/fonts
zipname=latex_wwu_ppt_2018

latex_engine=$1
case "$latex_engine" in
	lualatex|xelatex)
		;;
	'')
		latex_engine=lualatex
		;;
	*)
		echo "Invalid LaTeX engine (must be lualatex or xelatex): $latex_engine"
		exit 2
		;;
esac
if [ ! -f "$fontdir/MetaOffcPro-Bold.ttf" ]     || \
	[ ! -f "$fontdir/MetaOffcPro-Norm.ttf" ]    || \
	[ ! -f "$fontdir/MetaOffcPro-NormIta.ttf" ] || \
	[ ! -f "$fontdir/MetaScOffcPro-Bold.ttf" ]  || \
	[ ! -f "$fontdir/MetaScOffcPro-Norm.ttf" ]  || \
	[ ! -f "$fontdir/MetaScOffcPro-NormIta.ttf" ]; then
	echo "Font files missing in $fontdir/!"
	exit 1
fi

# clean up previous build
rm -rf "$zipname/"

olddir="$PWD"

tempdir=$(mktemp -d /tmp/latex-beamer.XXXXXX)
cp -r "$texdir/" "$tempdir/"
cd $tempdir
# delete dummy file
find "$fontdir/" -type f ! -name '*.ttf' -delete

# set up directories for compilation of example PDFs
mkdir -p de/vorlage/
mkdir -p en/template/

cp -r "$fontdir/" "$texdir/wwustyle/" \
	"$texdir"/*.sty \
	"$texdir/einstellungen.tex" \
	"$texdir/praesentation.tex" \
	'de/vorlage/'
cp -r "$fontdir/" "$texdir/wwustyle/" \
	"$texdir"/*.sty \
	"$texdir/settings.tex" \
	"$texdir/presentation.tex" \
	'en/template/'

cp -r de/vorlage/ de/beispiele/
mv de/beispiele/praesentation.tex de/beispiele/presentation.tex
cp -r en/template/ en/examples/

rm -r "$texdir/"

# compile examples
for d in de/beispiele en/examples; do
	cd "$d/"
	# generate all title backgrounds and color options
	for aspect_ratio in 4x3 16x9; do
		for background in belltower 'belltower,inverse' wedge 'wedge,inverse' prinz; do
			for color in 312 3135 7462; do
				aspect_ratio_beamer=$(echo "$aspect_ratio" | sed 's/x//')
				aspect_ratio_beamer=", aspectratio=$aspect_ratio_beamer"
				options="pantone$color,$background"
				# remove commas from file names
				filename=$(echo "${options}_${aspect_ratio}" | sed 's/,/_/g')
				cp presentation.tex "$filename.tex"
				# set options in the TeX file
				sed -i "s/]{beamer}/$aspect_ratio_beamer]{beamer}/" "$filename.tex"
				sed -i "s/pantone312]/$options]/" "$filename.tex"
				# use \bgbox for option “prinz”
				if [ "$background" = prinz ]; then
					sed -i 's/%\\title/\\title/' "$filename.tex"
					sed -i 's/%\\subtitle/\\subtitle/' "$filename.tex"
					sed -i 's/%\\author/\\author/' "$filename.tex"
					sed -i 's/%\\date/\\date/' "$filename.tex"
				fi
				# run compilations in parallel for improved speed
				latexmk "-$latex_engine" -interaction=nonstopmode -silent \
					"$filename.tex" &
			done
			wait
		done
		echo "$d/$aspect_ratio complete"
	done
	# remove source files
	rm -r $(basename "$fontdir/") wwustyle/ *.tex *.sty
	# remove auxiliary files
	rm *.aux *.log *.out *.toc *.fls *.fdb_latexmk *.synctex.gz *.nav *.snm
	cd "$tempdir"
done

# create .zip file
cd "$olddir"
cp -r "$tempdir/" "$zipname"
zip -r "$zipname.zip" "$zipname/"

rm -r "$tempdir"

