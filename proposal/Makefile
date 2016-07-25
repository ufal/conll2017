.PHONY: all
all: proposal.html

%.html: %.md
	pandoc --from markdown_github --to html --standalone --output $@ $<

.PHONY: clear
clear:
	rm -rf proposal.html
