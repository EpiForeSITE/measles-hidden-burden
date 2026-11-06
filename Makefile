MAKEFLAGS += --no-print-directory

REPORT_NAME=r0_$(R0)-epistorm_$(EPISTORM)-rash_contact_redux_$(RASH_CONTACT_REDUX)-isolation_willingness_$(ISO_WILL)-quarantine_willingness_$(Q_WILL)-contact_tracing_success_$(QT_SUCCESS)-vax_adults_$(VAX_ADULTS)

R0 ?= 12
EPISTORM ?= FALSE
RASH_CONTACT_REDUX ?= 0.2
ISO_WILL ?= 0.0
Q_WILL ?= 0.9
QT_SUCCESS ?= 0.8
VAX_ADULTS ?= baseline
TARGET_DIR ?= scenarios

R0_VALUES = 5 7 9 11 13 15 17
VAX_ADULTS_VALUES = baseline 78pct 86pct 93pct

# Main target to run the paper models
scenarios:
	@for r0 in $(R0_VALUES); do \
		R0=$$r0 $(MAKE) focal_scenarios || exit 1; \
	done
	quarto render $(TARGET_DIR)/README.qmd

# The three intervention scenarios at the current R0 and vaccination setting.
focal_scenarios:
	RASH_CONTACT_REDUX=0.00 QT_SUCCESS=0.00 make report
	RASH_CONTACT_REDUX=0.50 QT_SUCCESS=0.00 make report
	RASH_CONTACT_REDUX=0.75 QT_SUCCESS=0.25 make report

# The three focal scenarios at R0 = 9 for each adult vaccination assumption
population_immunity:
	@for vax_adults in $(VAX_ADULTS_VALUES); do \
		TARGET_DIR=population_immunity R0=9 VAX_ADULTS=$$vax_adults $(MAKE) focal_scenarios || exit 1; \
	done
	quarto render population_immunity/README.qmd

# Population, contact matrices, and vaccination data (see data/utaz_data.R)
data:
	Rscript data/utaz_data.R
	Rscript data/epistorm_matrix.R

# Checks of the data (see tests/tinytest)
test:
	Rscript -e 'r <- tinytest::run_test_dir("tests/tinytest", verbose = 1); print(summary(r)); if (!all(as.logical(r))) quit(status = 1)'

# Figure 4: phylodynamic panels (A-B) from the EBSP logs, ABM panels (C-D,
# R0 = 9) from the outputs in scenarios/, and both together. The paper_arms
# version draws the scenario with quarantine from the run without quarantine,
# as in the preprint (see Figure_Data/FigureABM.R)
figures:
	Rscript Figure_Data/FigureABM.R
	Rscript Figure_Data/FigureABM.R --paper-arms
	Rscript Figure_Data/FigurePhylodynamic.R

# Report generation
report:
	@if [ -f "$(TARGET_DIR)/$(REPORT_NAME).md" ]; then \
		echo "Skipping existing report: $(TARGET_DIR)/$(REPORT_NAME).md"; \
	else \
		if [ ! -d "$(TARGET_DIR)" ]; then \
			mkdir -p $(TARGET_DIR); \
		fi; \
		if [ ! -e "$(TARGET_DIR)/data" ]; then \
			ln -s ../data $(TARGET_DIR)/data; \
		fi; \
		cp template.qmd $(TARGET_DIR)/$(REPORT_NAME).qmd && \
		quarto render $(TARGET_DIR)/$(REPORT_NAME).qmd \
			-P r0=$(R0) \
			-P epistorm=$(EPISTORM) \
			-P rash_contact_redux=$(RASH_CONTACT_REDUX) \
			-P isolation_willingness=$(ISO_WILL) \
			-P quarantine_willingness=$(Q_WILL) \
			-P contact_tracing_success=$(QT_SUCCESS) \
			-P vax_adults=$(VAX_ADULTS) && \
		rm -f $(TARGET_DIR)/$(REPORT_NAME).qmd; \
	fi

clean:
	rm -rf $(TARGET_DIR)/*.rds $(TARGET_DIR)/*.md $(TARGET_DIR)/*_files

# Alias
sensitivity_r0: scenarios

# All sensitivity analysis
sensitivity_analysis: sensitivity_r0 sensitivity_epistorm sensitivity_rash_redux

PROB_VALUES = 0.0 0.25 0.5 0.75 1.0

sensitivity_epistorm:
	TARGET_DIR=sensitivity_epistorm EPISTORM=TRUE $(MAKE) scenarios

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
	quarto render sensitivity_rash_redux/README.qmd

.PHONY: data test figures scenarios focal_scenarios report clean population_immunity sensitivity_r0 sensitivity_epistorm sensitivity_rash_redux sensitivity_analysis
