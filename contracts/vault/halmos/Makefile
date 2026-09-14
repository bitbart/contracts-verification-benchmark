# Params
to = 10m
ver =                                   # Optional usage: make run ver=v1 
prop =                                  # Optional usage: make run prop=cancel-revert

# Version normalization: guarantees the 'v' prefix if only the number is entered (e.g. 1 -> v1)
VER_NORMALIZED = $(if $(ver),$(if $(patsubst v%,%,$(ver)),v$(patsubst v%,%,$(ver)),$(ver)),)

# Input files
VERSIONS_DIR = ../versions
PROPERTIES_DIR = .
GROUND_TRUTH = ../ground-truth.csv

# Selection of versions and properties (Adattato per Vault)
VERSIONS_FILES = $(if $(VER_NORMALIZED),\
    $(wildcard $(VERSIONS_DIR)/Vault_$(VER_NORMALIZED).sol),\
    $(wildcard $(VERSIONS_DIR)/*.sol))

PROPERTIES_FILES = $(if $(prop),\
    $(wildcard $(PROPERTIES_DIR)/$(prop).t.sol),\
    $(wildcard $(PROPERTIES_DIR)/*.t.sol))

# Output files
BUILD_DIR = build
OUTPUT_DIR = $(BUILD_DIR)/halmos
CONTRACTS_DIR = $(BUILD_DIR)/contracts
LOGS_DIR = $(OUTPUT_DIR)/logs
LIB_DIR = $(CONTRACTS_DIR)/lib
OUT = $(OUTPUT_DIR)/out.csv
CM = $(OUTPUT_DIR)/cm.csv
TABLE = $(OUTPUT_DIR)/table.md

# Path to vault/
ROOT_VAULT_HALMOS_CSV = ../halmos.csv

PYTHON = python

.PHONY: run setup contracts directories clean

#---------------------------- RUN --------------------------------#
run: $(TABLE)

$(TABLE): $(CM)
	@echo "Generating Halmos results table ($(TABLE))..."
	@echo "#### Halmos" > $(TABLE)
	@$(PYTHON) ../../../scripts/mdtable_gen.py --input $(CM) >> $(TABLE)

$(CM): $(GROUND_TRUTH) $(OUT)
	@echo "Generating Halmos confusion matrix ($(CM))..."
	@$(PYTHON) ../../../scripts/cm_gen.py --ground-truth $(GROUND_TRUTH) --results $(OUT) > $(CM)
	@cp -f $(OUT) $(ROOT_VAULT_HALMOS_CSV)

$(OUT): setup
	@echo "Running Halmos experiments..."
	@$(PYTHON) ../../../scripts/run_halmos.py \
		--contracts $(CONTRACTS_DIR) \
		--output $(OUTPUT_DIR) \
		--timeout $(to) \
		--halmos-dir $(CONTRACTS_DIR) \
		$(if $(VER_NORMALIZED),--version $(VER_NORMALIZED),) \
		$(if $(prop),--property $(prop),)

#---------------------------- SETUP ------------------------------#
setup: contracts directories
	 
contracts: $(CONTRACTS_DIR) $(LIB_DIR)
	@echo "Generating version-specific test files for Halmos..."
	@cp ./foundry.toml $(CONTRACTS_DIR)/
	@mkdir -p $(CONTRACTS_DIR)/versions
	@cp -r $(LIB_DIR) $(CONTRACTS_DIR)/versions/lib
	@for ver_file in $(notdir $(VERSIONS_FILES)); do \
		ver_name=$${ver_file%.sol}; \
		ver_short=$$(echo $$ver_name | sed 's/Vault_//'); \
		cp $(VERSIONS_DIR)/$$ver_file $(CONTRACTS_DIR)/versions/$$ver_short.sol; \
		for prop_file in $(PROPERTIES_FILES); do \
			prop_name=$$(basename $$prop_file .t.sol); \
			prop_name_safe=$$(echo $$prop_name | sed 's/-/_/g'); \
			target_file=$(CONTRACTS_DIR)/$${ver_short}_$${prop_name_safe}.t.sol; \
			sed -e "s/{{VERSION}}/$$ver_short/g" \
				-e "s/{{CONTRACT_NAME}}/VaultTest_$${ver_short}_$${prop_name_safe}/g" \
				-e "s/contract VaultTest/contract VaultTest_$${ver_short}_$${prop_name_safe}/g" \
				$$prop_file > $$target_file; \
		done; \
	done

directories: $(CONTRACTS_DIR) $(LOGS_DIR) $(LIB_DIR)

$(CONTRACTS_DIR):
	@mkdir -p $@

$(LOGS_DIR):
	@mkdir -p $@

$(LIB_DIR):
	@cp -r ../../../lib/ $@
	@rm -f $@/ERC20v2.sol
	@rm -f $@/ERC20v3.sol

#---------------------------- CLEAN ------------------------------#
clean:
	rm -rf $(BUILD_DIR)