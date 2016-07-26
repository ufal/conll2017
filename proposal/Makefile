.PHONY: all
all: proposal.html

%.html: %.md
	pandoc --from markdown --to html5 --output $@ $<

.PHONY: clear
clear:
	rm -rf proposal.html
