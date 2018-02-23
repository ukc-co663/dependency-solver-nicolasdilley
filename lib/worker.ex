defmodule Worker do
	def start(parentId,parsedInitial,[],[],parsedConstraints,package,parsedRepo) do
		result = DependencyManager.addAnotherPackageAndRecurse(parsedInitial,[],[],parsedConstraints,package,parsedRepo)
                                                                       
           if result != {:error} && result != [] do
             # sends the message
            send parentId,{:ok, result}
          	else
          	exit("no result")
          end
	end
end