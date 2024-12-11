.PHONY: pdf
pdf:
	pdflatex sample-sigconf
	bibtex sample-sigconf
	pdflatex sample-sigconf
	pdflatex sample-sigconf
	rm -f *.aux *.log *.bbl *.blg *.out

.PHONY: up
up:
	git pull
	git add .
	if [ -z "$(msg)" ]; then git commit -m "up"; else git commit -m "$(msg)"; fi
	git push
