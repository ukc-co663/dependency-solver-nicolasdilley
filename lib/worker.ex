defmodule Worker do
	def start(parentId,parsedInitial,seen,commands,parsedConstraints,package,parsedRepo) do
		result = DependencyManager.addAnotherPackageAndRecurse(parsedInitial,seen,commands,parsedConstraints,package,parsedRepo)
                                                                       
           if result != {:error} && result != [] do
             # sends the message
            send parentId,{:ok, result}
          	else
          	exit("no result")
          end
	end
end