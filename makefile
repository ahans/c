# This makefile creates a target to build and test each exercise using the provided example
# implementation. The exercise target depends on a list of other targets that
#   1) Copy the main test file and adjust it to include all tests,
#   2) Copy the example implementation so that it is used,
#   3) Copy the makefile and unittest framework,
#   4) Build and test the exercise.
#
# Use `make <slug>` to build and test a specific exercise. Simply running `make` builds and
# tests all available exercises.


# Macro to create the rules for one exercise.
# Arguments:
#   $(1) - slug
#   $(2) - slug with dashes replaced by underscores
#   $(3) - type of exercise: 'practice' or 'concept'
#   $(4) - name of test implementation: 'example' or 'exemplar'
define setup_exercise

# Copy the test file and removes TEST_IGNORE
build/exercises/$(3)/$(1)/test_$(2).c: exercises/$(3)/$(1)/test_$(2).c
	@mkdir -p $$(dir $$@)
	@sed 's#TEST_IGNORE();#// &#' $$< > $$@

# Copy example/exemplar implementation
build/exercises/$(3)/$(1)/$(2).c: exercises/$(3)/$(1)/.meta/$(4).c
	@mkdir -p $$(dir $$@)
	@cp $$< $$@
	@cp exercises/$(3)/$(1)/*.h build/exercises/$(3)/$(1)/.
	@if [ -e exercises/$(3)/$(1)/.meta/$(4).h ]; then \
		cp exercises/$(3)/$(1)/.meta/$(4).h build/exercises/$(3)/$(1)/$(2).h; \
	fi

# Copy Makefile
build/exercises/$(3)/$(1)/makefile: exercises/$(3)/$(1)/makefile
	@mkdir -p $$(dir $$@)
	@cp $$< $$@

# Copy the test framework
build/exercises/$(3)/$(1)/test-framework: $$(wildcard exercises/$(3)/$(1)/test-framework/*)
	@mkdir -p $$@
	@cp exercises/$(3)/$(1)/test-framework/* build/exercises/$(3)/$(1)/test-framework/

# Build the exercise.
build/exercises/$(3)/$(1)/tests.out: \
		build/exercises/$(3)/$(1)/test_$(2).c \
		build/exercises/$(3)/$(1)/$(2).c \
		build/exercises/$(3)/$(1)/makefile \
		build/exercises/$(3)/$(1)/test-framework
	$$(MAKE) -C build/exercises/$(3)/$(1) tests.out

# Build and run the memcheck variant.
build/exercises/$(3)/$(1)/memcheck.out: \
		build/exercises/$(3)/$(1)/test_$(2).c \
		build/exercises/$(3)/$(1)/$(2).c \
		build/exercises/$(3)/$(1)/makefile \
		build/exercises/$(3)/$(1)/test-framework
	$$(MAKE) -C build/exercises/$(3)/$(1) memcheck


# Top-level target for an exercise. The target above always runs the executable, regardless of any
# changes. Having the tests binary as a separate target in between allows make to skip anything
# that hasn't changed.
.PHONY: $(1)
$(1): build/exercises/$(3)/$(1)/tests.out build/exercises/$(3)/$(1)/memcheck.out

endef

PRACTICE_EXERCISES := $(notdir $(wildcard exercises/practice/*))
CONCEPT_EXERCISES := $(notdir $(wildcard exercises/concept/*))

.PHONY: all
all: $(PRACTICE_EXERCISES) $(CONCEPT_EXERCISES)

# Instantiate the macro for each practice exercise to create targets for each exercise.
$(foreach exercise,$(PRACTICE_EXERCISES),$(eval $(call setup_exercise,$(exercise),$(subst -,_,$(exercise)),practice,example)))
$(foreach exercise,$(CONCEPT_EXERCISES),$(eval $(call setup_exercise,$(exercise),$(subst -,_,$(exercise)),concept,exemplar)))

.PHONY: list-practice
list-practice:
	@for exercise in $(PRACTICE_EXERCISES); do \
		echo "$$exercise"; \
	done

.PHONY: list-concept
list-concept:
	@for exercise in $(CONCEPT_EXERCISES); do \
		echo "$$exercise"; \
	done

.PHONY: clean
clean:
	rm -rf build

.PHONY: help
help:
	@echo "Available targets:"
	@echo "  all            - Build and test all practice exercises (default)"
	@echo "  <slug>         - Build and test a specific exercise given by its slug"
	@echo "  clean          - Remove all build artifacts"
	@echo "  list-practice  - List all practice exercises"
	@echo "  list-concept   - List all concept exercises"
	@echo "  help           - Show this help message"
