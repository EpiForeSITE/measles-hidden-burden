
all:
	R0=5 $(MAKE) report && \
	R0=7 $(MAKE) report && \
	R0=9 $(MAKE) report && \
	R0=11 $(MAKE) report && \
	R0=13 $(MAKE) report && \
	R0=15 $(MAKE) report && \
	R0=17 $(MAKE) report

R0 ?= 12
EPISTORM ?= FALSE
RASH_CONTACT ?= 0.2
QUARANTINE_WILLINGNESS ?= 0.9

report: clean
	REPORT_NAME="r0_$(R0)-epistorm_$(EPISTORM)-rash_contact_$(RASH_CONTACT)-quarantine_willingness_$(QUARANTINE_WILLINGNESS)" && \
	cp template.qmd scenarios/$$REPORT_NAME.qmd && \
	quarto render scenarios/$$REPORT_NAME.qmd \
		-P r0=$(R0) \
		-P epistorm=$(EPISTORM) \
		-P rash_contact=$(RASH_CONTACT) \
		-P quarantine_willingness=$(QUARANTINE_WILLINGNESS) && \
	rm -f scenarios/$$REPORT_NAME.qmd

clean:
	rm -f scenarios/*.rds
