#!/bin/sh

texdir=tex
fontdir=tex/fonts
zipname=latex_wwu_ppt_2018
if [ ! -f "$fontdir/MetaOffcPro-Bold.ttf" ]   || \
	[ ! -f "$fontdir/MetaOffcPro-Norm.ttf" ]    || \
	[ ! -f "$fontdir/MetaOffcPro-NormIta.ttf" ] || \
	[ ! -f "$fontdir/MetaScOffcPro-Bold.ttf" ]  || \
	[ ! -f "$fontdir/MetaScOffcPro-Norm.ttf" ]  || \
	[ ! -f "$fontdir/MetaScOffcPro-NormIta.ttf" ]; then
	echo "Font files missing in $fontdir/!"
	exit 1
fi

olddir=$PWD

tempdir=$(mktemp -d /tmp/latex-beamer.XXXXXX)
cp -r "$texdir/" "$tempdir/"
cd $tempdir
# delete dummy file
find "$fontdir/" -type f ! -name '*.ttf' -delete

mkdir -p de/vorlage/
mkdir -p en/template/

cp -r "$fontdir/" "$texdir/wwustyle/" \
	"$texdir/wwustyle.sty" \
	"$texdir/einstellungen.tex" \
	"$texdir/praesentation.tex" \
	'de/vorlage/'
cp -r "$fontdir/" "$texdir/wwustyle/" \
	"$texdir/wwustyle.sty" \
	"$texdir/settings.tex" \
	"$texdir/presentation.tex" \
	'en/template/'

cp -r de/vorlage/ de/beispiele/
mv de/beispiele/praesentation.tex de/beispiele/presentation.tex
cp -r en/template/ en/examples/

rm -r "$texdir/"

for d in de/beispiele en/examples; do
	cd "$d/"
	# generate all title backgrounds and color options
	for background in belltower 'belltower,inverse' wedge 'wedge,inverse' prinz; do
		for color in 312 3135 7462 black7 315 369 390; do
			options="pantone$color,$background"
			# remove commas from file names
			filename=$(echo "$options" | sed 's/,/_/g')
			cp presentation.tex "$filename.tex"
			# use \bgbox for option “prinz”
			if [ "$background" = prinz ]; then
				sed -i 's/%\\title/\\title/' "$filename.tex"
				sed -i 's/%\\subtitle/\\subtitle/' "$filename.tex"
				sed -i 's/%\\author/\\author/' "$filename.tex"
				sed -i 's/%\\date/\\date/' "$filename.tex"
			fi
			sed -i "s/pantone312]/$options]/" "$filename.tex"
		done
	done
	rm presentation.tex
	# compile all .tex files in the current directory
	# run compilations in parallel for improved speed
	latexmk -lualatex -interaction=nonstopmode -silent pantone3[0-1]*.tex &
	latexmk -lualatex -interaction=nonstopmode -silent pantone3[2-9]*.tex &
	latexmk -lualatex -interaction=nonstopmode -silent pantone[a-z0-24-9]*.tex &
	wait
	# remove source files
	rm -r $(basename "$fontdir/") wwustyle/ *.tex *.sty
	# remove auxiliary files
	rm *.aux *.log *.out *.toc *.fls *.fdb_latexmk *.synctex.gz *.nav *.snm
	echo "$d complete"
	cd "$tempdir"
done

# create .zip file
cd "$olddir"
cp -r "$tempdir/" "$zipname"
zip -r "$zipname.zip" "$zipname/"

rm -r "$tempdir"

