defmodule PackageParser do
	@doc """
	  parse a string in json representing a repo 
	  and return a Repo struct

  	"""
	def parseRepo (repo) do
		parsedRepo = Poison.decode!(repo)

		newRepo = Enum.sort(parsedRepo, &(&1["size"] < &2["size"]))
		IO.inspect newRepo
		newRepo
	end

	def parseConstraints(constraints)do
		Poison.decode!(constraints)
	end

	def parseInitialState (state) do
		Poison.decode!(state)
	end
end