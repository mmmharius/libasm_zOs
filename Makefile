NAME        = libasm_zOs.a
SRCS        = ft_strlen.s ft_strcpy.s ft_strcmp.s
OBJDIR      = obj
OBJS        = $(addprefix $(OBJDIR)/, $(SRCS:.s=.o))
NASM_FORMAT = elf32

GREEN  = \033[0;32m
RED    = \033[0;31m
BLUE   = \033[0;34m
RESET  = \033[0m
BOLD   = \033[1m

define run_cmd
	@printf "  $(BLUE)->$(RESET) %-40s" "$(2)"; \
	if $(1) > /tmp/libasm_build.log 2>&1; then \
		printf " $(GREEN)[OK]$(RESET)\n"; \
	else \
		printf " $(RED)[KO]$(RESET)\n"; \
		cat /tmp/libasm_build.log; \
		exit 1; \
	fi
endef

define del_path
	@if [ -e "$(1)" ]; then \
		printf "  $(BLUE)->$(RESET) $(RESET)%-40s$(RESET) $(RED)[DELETED]$(RESET)\n" "$(1)"; \
		rm -rf "$(1)"; \
	fi
endef

all: $(OBJDIR) $(NAME)

$(OBJDIR):
	@mkdir -p $(OBJDIR)

$(OBJDIR)/%.o: %.s | $(OBJDIR)
	$(call run_cmd,nasm -f $(NASM_FORMAT) $< -o $@,asm    $<)

$(NAME): $(OBJS)
	$(call run_cmd,ar rcs $@ $(OBJS),ar     $@)

main: $(NAME) main.c
	$(call run_cmd,gcc -fPIC main.c $(NAME) -o libasm,cc     libasm)

clean:
	$(call del_path,$(OBJDIR))

fclean: clean
	$(call del_path,$(NAME))
	$(call del_path,libasm)
	$(call del_path,main)

re: fclean all

.PHONY: all clean fclean re