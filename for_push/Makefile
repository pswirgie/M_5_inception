# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: pswirgie <pswirgie@student.42.fr>          +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2026/07/04 10:52:43 by pswirgie          #+#    #+#              #
#    Updated: 2026/10/13 09:20:38 by pswirgie         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

# ================= VARIABLES ================= #

CXX				:= c++
CXXFLAGS		:= -Wall -Wextra -Werror -std=c++98
MAKEFLAGS		+= --no-print-directory
BUILD_DIR		:= .obj

NAME		:= PmergeMe

# Colors
GREEN		:='\033[0;32m'
NC			:='\033[0m'


# Sources
SRC_BASENAMES := main PmergeMe
SRCS := $(addsuffix .cpp,$(SRC_BASENAMES))

OBJS		:= $(SRCS:%.cpp=$(BUILD_DIR)/%.o)

# ================= COMMANDS ================= #
all: $(NAME)

$(NAME): $(BUILD_DIR) $(OBJS)
	@$(CXX) $(OBJS) $(INCLUDES) -o $(NAME)
	@echo $(GREEN)"\n✨ $(NAME) build created. ✨\n"$(NC)
	@clear
	@echo $(GREEN)"💫 All compiled 💫\n"$(NC)

$(BUILD_DIR):
	@mkdir -p $@

# Compilation .c -> .o
$(BUILD_DIR)/%.o: %.cpp $(HEADERS)
	@mkdir -p $(dir $@)
	@$(CXX) $(CXXFLAGS) $(INCLUDES) -c $< -o $@

sorted: CXXFLAGS += -g -D SORTED
sorted: fclean
	@$(MAKE) --no-print-directory CXXFLAGS="$(CXXFLAGS)" all

debug: CXXFLAGS += -g -D DEBUG
debug: fclean
	@$(MAKE) --no-print-directory CXXFLAGS="$(CXXFLAGS)" all

clean:
	@rm -rf $(BUILD_DIR)
	@echo $(GREEN)"$(NAME) build is clean. 🧹"$(NC)

fclean: clean
	@rm -f $(NAME)
	@echo $(GREEN)"$(NAME) executer is clean. 🧹"$(NC)

re: fclean 
	$(MAKE) --no-print-directory all


# ================= Archives ================= #

DEPTH	:= 2
DATE	:= $(shell date +"%y_%m_%d_%H-%M-%S")

ifeq ($(DEPTH), 1)
	TARGET_BASE := $(shell dirname $(CURDIR))
else ifeq ($(DEPTH), 2)
	TARGET_BASE := $(shell dirname $(shell dirname $(CURDIR)))
endif

TARGET_DIR := $(TARGET_BASE)/00_${NAME}_backups

zip:
	@zip ${NAME}_${DATE}.zip *
	@if [ ! -d "$(TARGET_DIR)" ]; then \
		echo "Folder unfound, created"; \
		mkdir -p "$(TARGET_DIR)"; \
	fi
	@mv ${NAME}_${DATE}.zip $(TARGET_DIR);
	@echo ${GREEN}"Backup suCXXessfully done."${NC};

.PHONY: all clean fclean re setup unzip zip