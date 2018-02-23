defmodule ConflictResolver do
	
	@doc """
		resolve conflicts take a package and a list of package.
		It checks if the package conflict with any of the packages in the state. 
		if it doesnt return {:ok} or return {:error}
		"""
		@spec resolveConflicts(%{},[%{}],[%{}]) :: {atom}
		def resolveConflicts(package,state,repo) do
			conflicts = Map.get(package,"conflicts",[])
			if Enum.all?(state,fn pack -> 
				(if Enum.all?(conflicts, fn conflict -> resolveConflict(DependencyManager.findPackage(repo,pack),conflict) == {:ok} end) do
					{:ok}
				else
					{:error} 
				end)
					 == {:ok} end) do
					{:ok}
				else
					{:error}
			end
		
		end


	@doc """
		check if the package conflict with a particular conflict
		"""
		@spec resolveConflict(%{},%{}) :: {:ok} | {:error}
		def resolveConflict(package,conflict) do
			cond do
				String.contains?(conflict,">=") ->
					[name,version] = String.split(conflict, ">=")

					if Map.get(package,"name") == name do
						if versionCompare(Map.get(package,"version"),version) >= 0 do
							{:ok}
						else
							{:error}
						end

					else
						{:ok}
					end



				String.contains?(conflict,"<=") ->

					[name,version] = String.split(conflict, "<=")

					if Map.get(package,"name") == name do
						if versionCompare(Map.get(package,"version"),version) <= 0 do
							{:ok}
						else
							{:error}
						end
					else
						{:ok}
					end

				String.contains?(conflict,">") ->
					[name,version] = String.split(conflict, ">")

					if Map.get(package,"name") == name do
						if versionCompare(Map.get(package,"version"),version) > 0 do
							{:ok}
						else
							{:error}
						end

					else
						{:ok}
					end
				String.contains?(conflict,"<") ->


					[name,version] = String.split(conflict, "<")

					if package["name"] == name do
						if versionCompare(Map.get(package,"version"),version) < 0 do
							{:ok}
						else
							{:error}
						end
					else
						{:ok}
					end
				true -> if (package["name"] != conflict) do
								{:ok}
							else
								{:error}
							end
				end
		end

		@doc """
			Return a positive number if vers1 is bigger than vers2
			negative if less and 0 if equal
		"""
		def versionCompare(vers1,vers2)do
			vals1 = List.to_integer(String.to_charlist(String.replace(vers1,".","")))
			vals2 = List.to_integer(String.to_charlist(String.replace(vers2,".","")))

			(vals1 - vals2)
		end
	end