R0 ?= 12
EPISTORM ?= FALSE
RASH_CONTACT_REDUX ?= 0.2
ISO_WILL ?= 0.0
Q_WILL ?= 0.9
QT_SUCCESS ?= 0.8

R0_VALUES = 5 7 9

all:
	for r0 in $(R0_VALUES); do \
		R0=$$r0 RASH_CONTACT_REDUX=0.00 QT_SUCCESS=0.00  make report && \
		R0=$$r0 RASH_CONTACT_REDUX=0.50 QT_SUCCESS=0.00  make report && \
		R0=$$r0 RASH_CONTACT_REDUX=0.75 QT_SUCCESS=0.25  make report; \
	done

report:
	REPORT_NAME="r0_$(R0)-epistorm_$(EPISTORM)-rash_contact_redux_$(RASH_CONTACT_REDUX)-isolation_willingness_$(ISO_WILL)-quarantine_willingness_$(Q_WILL)-contact_tracing_success_$(QT_SUCCESS)" && \
	cp template.qmd scenarios/$$REPORT_NAME.qmd && \
	quarto render scenarios/$$REPORT_NAME.qmd \
		-P r0=$(R0) \
		-P epistorm=$(EPISTORM) \
		-P rash_contact_redux=$(RASH_CONTACT_REDUX) \
		-P isolation_willingness=$(ISO_WILL) \
		-P quarantine_willingness=$(Q_WILL) \
		-P contact_tracing_success=$(QT_SUCCESS) && \
	rm -f scenarios/$$REPORT_NAME.qmd

clean:
	rm -rf scenarios/*.rds scenarios/*.md scenarios/*_files
