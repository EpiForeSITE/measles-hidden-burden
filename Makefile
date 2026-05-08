MAKEFLAGS += --no-print-directory

REPORT_NAME=r0_$(R0)-epistorm_$(EPISTORM)-rash_contact_redux_$(RASH_CONTACT_REDUX)-isolation_willingness_$(ISO_WILL)-quarantine_willingness_$(Q_WILL)-contact_tracing_success_$(QT_SUCCESS)

R0 ?= 12
EPISTORM ?= FALSE
RASH_CONTACT_REDUX ?= 0.2
ISO_WILL ?= 0.0
Q_WILL ?= 0.9
QT_SUCCESS ?= 0.8
TARGET_DIR ?= scenarios

R0_VALUES = 5 7 9

# Main target to run the paper models
main:
	@for r0 in $(R0_VALUES); do \
		R0=$$r0 RASH_CONTACT_REDUX=0.00 QT_SUCCESS=0.00  make report && \
		R0=$$r0 RASH_CONTACT_REDUX=0.50 QT_SUCCESS=0.00  make report && \
		R0=$$r0 RASH_CONTACT_REDUX=0.75 QT_SUCCESS=0.25  make report; \
	done

# Report generation
report:
	@if [ -f "$(TARGET_DIR)/$(REPORT_NAME).md" ]; then \
		echo "Skipping existing report: $(TARGET_DIR)/$(REPORT_NAME).md"; \
	else \
		if [ ! -d "$(TARGET_DIR)" ]; then \
			mkdir -p $(TARGET_DIR); \
		fi; \
		if [ ! -f "$(TARGET_DIR)/data" ]; then \
			cd $(TARGET_DIR) && ln -s ../data data && cd ..; \
		fi; \
		cp template.qmd $(TARGET_DIR)/$(REPORT_NAME).qmd && \
		quarto render $(TARGET_DIR)/$(REPORT_NAME).qmd \
			-P r0=$(R0) \
			-P epistorm=$(EPISTORM) \
			-P rash_contact_redux=$(RASH_CONTACT_REDUX) \
			-P isolation_willingness=$(ISO_WILL) \
			-P quarantine_willingness=$(Q_WILL) \
			-P contact_tracing_success=$(QT_SUCCESS) && \
		rm -f $(TARGET_DIR)/$(REPORT_NAME).qmd; \
	fi

clean:
	rm -rf $(TARGET_DIR)/*.rds $(TARGET_DIR)/*.md $(TARGET_DIR)/*_files

# Alias
sensitivity_r0: main

# All sensitivity analysis
sensitivity_analysis: sensitivity_r0 sensitivity_epistorm sensitivity_rash_redux

PROB_VALUES = 0.0 0.25 0.5 0.75 1.0

sensitivity_epistorm:
	TARGET_DIR=sensitivity_epistorm EPISTORM=TRUE $(MAKE) main

sensitivity_rash_redux:
	for prob0 in $(PROB_VALUES); do \
		for prob1 in $(PROB_VALUES); do \
			TARGET_DIR=sensitivity_rash_redux \
			R0=9 \
			RASH_CONTACT_REDUX=$$prob0 \
			QT_SUCCESS=$$prob1 \
			$(MAKE) report; \
		done; \
	done

.PHONY: main report clean sensitivity_r0 sensitivity_epistorm sensitivity_rash_redux sensitivity_analysis
