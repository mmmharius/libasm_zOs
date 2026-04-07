NAME = libasm.a

SRCS = ft_strlen.s ft_strcpy.s ft_strcmp.s
OBJDIR = obj
OBJS = $(addprefix $(OBJDIR)/, $(SRCS:.s=.o))

NASM_FORMAT = elf64

all: $(OBJDIR) $(NAME)

$(OBJDIR):
	mkdir -p $(OBJDIR)

$(OBJDIR)/%.o: %.s | $(OBJDIR)
	nasm -f $(NASM_FORMAT) $< -o $@

$(NAME): $(OBJS)
	ar rcs $@ $(OBJS)

clean:
	rm -rf $(OBJDIR)

fclean: clean
	rm -f $(NAME) libasm main

re: fclean all

main: $(NAME) main.c
	gcc -fPIC main.c $(NAME) -o libasm

.PHONY: all clean fclean re
