# The include directive tells make to suspend reading the current makefile 
# and read one or more other makefiles before continuing.
include Make.inc

# A phony target is one that is not really the name of a file;
# rather it is just a name for a recipe to be executed when you make an
# explicit request. There are two reasons to use a phony target: to avoid
# a conflict with a file of the same name, and to improve performance.
.PHONY = all clean

# $(addprefix prefix,names…)
# The argument names is regarded as a series of names, separated by whitespace;
# prefix is used as a unit. The value of prefix is prepended to the front of
# each individual name and the resulting larger names are concatenated with single
# spaces between them.

# $(patsubst pattern,replacement,text)
# Finds whitespace-separated words in text that match pattern and replaces them with
# replacement. Here pattern may contain a ‘%’ which acts as a wildcard, matching any
# number of any characters within a word. If replacement also contains a ‘%’, the ‘%’
# is replaced by the text that matched the ‘%’ in pattern. Only the first ‘%’ in the
# pattern and replacement is treated this way; any subsequent ‘%’ is unchanged.
OBJS = $(addprefix $(BUILD_DIR)/,$(patsubst %.c,%.o,$(SOURCES))) 

## $(shell command)
## It takes as an argument a shell command and evaluates to the output of the command.
$(shell mkdir -p $(DEPS_DIR) > /dev/null)

## These are the special GCC-specific flags which convince the compiler to generate 
## the dependency file.
## -MT $@
## Set the name of the target in the generated dependency file.
## -MD
## Generate dependency information as a side-effect of compilation, not instead of compilation.
## -MP
## Adds a target for each prerequisite in the list, to avoid errors when deleting files.
## -MF $(DEPS_DIR)/$*.Td
## Write the generated dependency file to a temporary location $(DEPS_DIR)/$*.Td.
DEPS = -MT $@ -MD -MP -MF $(DEPS_DIR)/$*.Td

## First rename the generated temporary dependency file to the real dependency file. 
## We do this in a separate step so that failures during the compilation won’t leave 
## a corrupted dependency file. Second touch the object file; it’s been reported that 
## some versions of GCC may leave the object file older than the dependency file, which 
## causes unnecessary rebuilds.
POSTCOMPILE = @mv -f $(DEPS_DIR)/$*.Td $(DEPS_DIR)/$*.d && touch $@

# A rule in the makefile tells Make how to execute a series of commands
# in order to build a target file from source files. It also specifies a
# list of dependencies of the target file.

# target: dependencies ...
#         commands
#         ...
all: $(BUILD_DIR)/$(TARGET) 

# A target pattern is composed of a ‘%’ between a prefix and a suffix, either
# or both of which may be empty. The pattern matches a file name only if the
# file name starts with the prefix and ends with the suffix, without overlap.
# The text between the prefix and the suffix is called the stem. Thus, when
# the pattern ‘%.o’ matches the file name test.o, the stem is ‘test’. The pattern
# rule prerequisites are turned into actual file names by substituting the stem
# for the character ‘%’. Thus, if in the same example one of the prerequisites
# is written as ‘%.c’, it expands to ‘test.c’.

# $@ The file name of the target of the rule.
# $< The name of the first prerequisite.
# $^ The names of all the prerequisites, with spaces between them.
# $* The stem with which an implicit rule matches.

## You can cancel a built-in implicit rule by defining a pattern rule with the
## same target and prerequisites, but no recipe.
%.o: %.c

# Occasionally, you have a situation where you want to impose a specific ordering
# on the rules to be invoked without forcing the target to be updated if one of
# those rules is executed. In that case, you want to define order-only prerequisites.
$(BUILD_DIR)/%.o: %.c $(DEPS_DIR)/%.d | $(BUILD_DIR)
	$(CC) $(DEPS) -c $< $(CFLAGS) -o $@
	$(POSTCOMPILE)

$(BUILD_DIR)/$(TARGET): $(OBJS) 
	$(CC) $^ -o $@ 

# Normally make prints each line of the recipe before it is executed.
# When a line starts with ‘@’, the echoing of that line is suppressed.
$(BUILD_DIR):
	@mkdir $@

# Create a phony target to clean the project in case we want to rebuild it
# from scratch.
clean:
	@rm -rf $(BUILD_DIR) $(DEPS_DIR)

## Create a pattern rule with an empty recipe, so that make won’t fail if the 
## dependency file doesn’t exist.
$(DEPS_DIR)/%.d: ;

## Mark the dependency files precious to make, so they won’t be automatically 
## deleted as intermediate files.
.PRECIOUS: $(DEPS_DIR)/%.d

## Include the dependency files that exist: translate each file listed in SOURCES 
## into its dependency file. Use wildcard to avoid failing on non-existent files.
## $(wildcard pattern…)
## This string, used anywhere in a makefile, is replaced by a space-separated list 
## of names of existing files that match one of the given file name patterns. If no 
## existing file name matches a pattern, then that pattern is omitted from the output 
## of the wildcard function.
include $(wildcard $(patsubst %.c,$(DEPS_DIR)/%.d,$(SOURCES)))
