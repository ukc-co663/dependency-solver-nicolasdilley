all:		

	-wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb && dpkg -i erlang-solutions_1.0_all.deb
	-apt-get update -y
	-apt-get install esl-erlang -y
	-apt-get install elixir -y
	-mix local.hex --force
	-MIX_ENV=prod mix escript.build