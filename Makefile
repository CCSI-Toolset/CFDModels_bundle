# A simple makefile for creating the High Resolution CFD Models bundled product
VERSION    := $(shell git describe --tags --dirty)
PRODUCT    := CFD Models Bundle
PROD_SNAME := CFDModels_bundle
LICENSE    := LICENSE.md
PKG_DIR    := CCSI_$(PROD_SNAME)_$(VERSION)
PACKAGE    := $(PKG_DIR).zip

CATEGORIES := Sorbents Solvents

TARBALLS := *.tgz
ZIPFILES := *.zip

# The bundled packages, as found in each category subdir
SUB_PACKAGES := $(foreach c,$(CATEGORIES), $(wildcard $c/$(TARBALLS) $c/$(ZIPFILES)))

PAYLOAD := docs/*.pdf \
	README.md \
	$(LICENSE)

# Get just the top part (not dirname) of each entry so cp -r does the right thing
PAYLOAD_TOPS := $(foreach v,$(PAYLOAD),$(shell echo $v | cut -d'/' -f1))
# And the payload (including expanded projects) with the PKG_DIR prepended
PKG_PAYLOAD := $(addprefix $(PKG_DIR)/, $(PAYLOAD) $(basename $(SUB_PACKAGES)))

# OS detection & changes
UNAME := $(shell uname)
ifeq ($(UNAME), Linux)
  MD5BIN=md5sum
endif
ifeq ($(UNAME), Darwin)
  MD5BIN=md5
endif
ifeq ($(UNAME), FreeBSD)
  MD5BIN=md5
endif

.PHONY: all clean $(CATEGORIES)

all: $(PACKAGE)

# Go into each category's subdir and break open the archives there
# into the corresponding subdir in the PKG_DIR
$(CATEGORIES):
	@echo "Packaging $@"
	@mkdir -p $(PKG_DIR)/$@
	@$(MAKE) -C $@ clean
	@$(MAKE) -C $@



$(PACKAGE): $(CATEGORIES) $(PAYLOAD) 
	@echo "Packaging $(PKG_DIR)"
	@mkdir -p $(PKG_DIR)
	@for cat in $(CATEGORIES); do \
	for tb in $$cat/**{,/*}/$(TARBALLS); do \
	  if [ -f $$tb ]; then\
	    tar -xf $$tb -C $(PKG_DIR)/$$cat/; \
	  fi; \
	done; \
	for zf in $$cat/*/$(ZIPFILES); do \
	  if [ -f $$zf ]; then\
	    unzip -qo $$zf -d $(PKG_DIR)/$$cat; \
	  fi; \
	done; \
	done
	@cp -r $(PAYLOAD_TOPS) $(PKG_DIR)
	@zip -qXr $(PACKAGE) $(PKG_DIR)
	@$(MD5BIN) $(PACKAGE)
	@rm -rf $(PKG_DIR)

clean:
	@rm -rf $(PACKAGE) $(PKG_DIR)
