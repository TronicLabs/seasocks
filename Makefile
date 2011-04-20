default: all
C_SRC=src/main/c
TEST_SRC=src/test/c
APPS_SRC=src/app/c

INCLUDES=-I $(C_SRC) -Iinclude -Llib
CPPFLAGS=-g -O2 -m64 -fPIC -pthread -Wreturn-type -W -Werror $(INCLUDES) -std=gnu++0x

STATIC_LIBS= 
APP_LIBS=

.PHONY: all clean run test clobber

OBJ_DIR=obj
BIN_DIR=bin

FIG_DEP=.fig-up-to-date
UNAME_R:=$(shell uname -r)
ifeq "" "$(findstring el5,$(UNAME_R))"
  PLATFORM=ubuntu
  CC=g++
else
  PLATFORM=redhat
  GCC_DIR=/site/apps/gcc-4.5.0
  CC=$(GCC_DIR)/bin/g++
  GCC_LIB_PATH=$(GCC_DIR)/lib64
  export LD_LIBRARY_PATH=$(GCC_LIB_PATH)
endif

$(FIG_DEP): package.fig
	rm -rf lib include
	fig -u --config $(PLATFORM) && touch $@

CPP_SRCS=$(shell find $(C_SRC) -name '*.cpp')
APPS_CPP_SRCS=$(shell find $(APPS_SRC) -name '*.cpp')
TARGETS=$(patsubst $(APPS_SRC)/%.cpp,$(BIN_DIR)/%,$(APPS_CPP_SRCS))

apps: $(TARGETS)
all: apps $(BIN_DIR)/libseasocks.so $(BIN_DIR)/libseasocks.a test

debug:
	echo $($(DEBUG_VAR))

fig: $(FIG_DEP)


OBJS=$(patsubst $(C_SRC)/%.cpp,$(OBJ_DIR)/%.o,$(CPP_SRCS))
APPS_OBJS=$(patsubst $(APPS_SRC)/%.cpp,$(OBJ_DIR)/%.o,$(APPS_CPP_SRCS))
ALL_OBJS=$(OBJS) $(APPS_OBJS)

-include $(ALL_OBJS:.o=.d)

$(APPS_OBJS) : $(OBJ_DIR)/%.o : $(APPS_SRC)/%.cpp $(FIG_DEP)
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) -fPIC -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -c -o "$@" "$<" 

$(OBJS) : $(OBJ_DIR)/%.o : $(C_SRC)/%.cpp $(FIG_DEP)
	@mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) -fPIC -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -c -o "$@" "$<" 

$(TARGETS) : $(BIN_DIR)/% : $(OBJ_DIR)/%.o $(OBJS)
	mkdir -p $(BIN_DIR)
	$(CC) $(CPPFLAGS) -o $@ $^ $(STATIC_LIBS) $(APP_LIBS)

$(BIN_DIR)/libseasocks.so: $(OBJS)
	mkdir -p $(BIN_DIR)
	$(CC) -shared $(CPPFLAGS) -o $@ $^ $(STATIC_LIBS)

$(BIN_DIR)/libseasocks.a: $(OBJS)
	mkdir -p $(BIN_DIR)
	-rm -f $(BIN_DIR)/libseasocks.a
	ar cq $@ $^

run: $(BIN_DIR)/ws_test
	$(BIN_DIR)/ws_test

$(BIN_DIR)/test_ssoauthenticator: $(TEST_SRC)/test_ssoauthenticator.cpp $(BIN_DIR)/libseasocks.a
	$(CC) $(CPPFLAGS) -I $(TEST_SRC) -o $@ $^
	
.tests-pass: $(BIN_DIR)/test_ssoauthenticator
	@rm -f .tests-pass
	$(BIN_DIR)/test_ssoauthenticator
	@touch .tests-pass

test: .tests-pass

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR) *.tar.gz .tests-pass

clobber: clean
	rm -rf lib include $(FIG_DEP)
