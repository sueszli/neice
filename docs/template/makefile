.PHONY: pdf
pdf:
	pdflatex report
	bibtex report
	pdflatex report
	pdflatex report
	rm -f *.aux *.log *.bbl *.blg *.out

.PHONY: up
up:
	git pull
	git add .
	if [ -z "$(msg)" ]; then git commit -m "up"; else git commit -m "$(msg)"; fi
	git push
