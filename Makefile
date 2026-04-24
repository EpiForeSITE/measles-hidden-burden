
all:
	R0=8 $(MAKE) report && \
	R0=10 $(MAKE) report && \
	R0=12 $(MAKE) report && \
	R0=15 $(MAKE) report

R0 ?= 12
report:
	quarto render short-creek.qmd \
		--output short-creek-$(R0).md \
		-P r0=$(R0)