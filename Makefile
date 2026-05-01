
all:
	R0=8 $(MAKE) report && \
	R0=10 $(MAKE) report && \
	R0=12 $(MAKE) report && \
	R0=14 $(MAKE) report && \
	R0=16 $(MAKE) report && \
	R0=18 $(MAKE) report && \
	R0=15 $(MAKE) report

R0 ?= 12
EPISTORM ?= FALSE
report: clean
	cp template.qmd utah-arizona-$(R0)-$(EPISTORM).qmd && \
	quarto render utah-arizona-$(R0)-$(EPISTORM).qmd \
		-P r0=$(R0) \
		-P epistorm=$(EPISTORM) && \
	rm -f utah-arizona-$(R0)-$(EPISTORM).qmd

clean:
	rm -f utah-arizona*.qmd
