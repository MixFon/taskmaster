# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: widraugr <marvin@42.fr>                    +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2018/11/29 13:07:44 by widraugr          #+#    #+#              #
#    Updated: 2021/09/28 10:41:32 by mixfon           ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

NAME = taskmaster

CLIENT = client

all : $(NAME) $(CLIENT)

$(NAME): 
	swift build
	cp .build/debug/taskmaster .
	cp .build/debug/client .

fclean:
	@/bin/rm -rf $(NAME)
	@/bin/rm -rf $(CLIENT)

	
re: fclean all 

