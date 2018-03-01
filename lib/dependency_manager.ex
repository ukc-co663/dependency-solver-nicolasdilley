defmodule DependencyManager do
  @moduledoc """
  Documentation for DependencyManager.
  """

  @doc """
  Main function.

  ## Edependencyamples

      iedependency> DependencyManager.main()
      :world

  """

  def main(args \\ []) do

    {_,repo} = File.read(Enum.at(args,0))
    {_,initial} = File.read(Enum.at(args,1))
    {_,constraints} = File.read(Enum.at(args,2))

    # Parse repo 
    parsedRepo = PackageParser.parseRepo(repo)
    #parse Initial state
    parsedInitial = PackageParser.parseInitialState(initial)
    #parse constraints
    parsedConstraints = PackageParser.parseConstraints(constraints)

    # Go through each constraints and resolve them
    # spawn a worker to do the job 
    #  the first worker that finds a solution returns it and the result gets printed

    startProcesses(parsedRepo,parsedInitial,parsedConstraints)
    end

  def startProcesses(parsedRepo,parsedInitial,parsedConstraints)do
    Enum.each(parsedRepo, fn package -> spawn_link(Worker,:start,[self(),parsedInitial,[],[],parsedConstraints,package,parsedRepo]) end)

    send(Kernel.length(parsedRepo) - 1)
  end

  def send(nbOfProcs) do
    receive do
      {:ok, result} -> print(result)
      {:error} when nbOfProcs > 0 -> send(nbOfProcs - 1)
      _ -> IO.puts "None"
    end
  end


  def findPackage([],_) do
    {:error}
  end

  def findPackage([repo|repos],repoName) do
      cond do
        String.contains?(repoName,">") ->
          [name,version] = String.split(repoName, ">")
          if Map.get(repo,"name") == name && repo["version"] == version do
                  repo 
                else 
                  findPackage(repos,repoName)
                end
          
        String.contains?(repoName,"<") ->
          [name,version] = String.split(repoName, "<")
          if Map.get(repo,"name") == name && repo["version"] == version do
                  repo 
                else 
                  findPackage(repos,repoName)
                end
        String.contains?(repoName,">=") ->
          [name,version] = String.split(repoName, ">=")

          if Map.get(repo,"name") == name && repo["version"] == version do
                  repo 
                else 
                  findPackage(repos,repoName)
                end

        String.contains?(repoName,"<=") ->
          [name,version] = String.split(repoName, "<=")
          if Map.get(repo,"name") == name && repo["version"] == version do
                  repo 
                else 
                  findPackage(repos,repoName)
                end
        String.contains?(repoName,"=") ->
          [name,version] = String.split(repoName, "=")
          if repo["name"] == name && repo["version"] == version do
                  repo 
                else 
                  findPackage(repos,repoName)
            end
        true -> 
                if Map.get(repo,"name") == repoName do
                  repo 
                else 
                  findPackage(repos,repoName)
                end
    end
  end

  


  def search(initial,seen,commands,constraints,repo) do
    case valid(initial,repo) do
        false -> {:error}
        true -> 
              # our initial is valid, lets check if has been seen
              case !seen?(initial,seen) do
                  false -> {:error}
                  true -> 
                    #make all the package seen 
                    newSeen = seen!(initial,seen)
                   
                    # checks if the states meets the constraints
                    case !meetConstraints?(initial,constraints,repo) do
                          false -> commands
                          true ->
                              # this initial state does not meet the constraints so lets add another package and recurse
                             Enum.reduce_while(repo,[],fn(package,toReturn) ->  result = addAnotherPackageAndRecurse(initial,newSeen,commands,constraints,package,repo)
                                                                       
                                                                      if result != {:error} && result != [] do
                                                                        {:halt, result}
                                                                      else 
                                                                        {:cont, toReturn}
                                                                      end

                  
                             end)
                    end
                  end
    end            
  end

  def addAnotherPackageAndRecurse(initial,seen,commands,constraints,package,repo) do
    packageFullName = package["name"] <> "=" <>package["version"]
    commandSign = case packageFullName in initial do
                    false -> "+"
                    _ -> "-"
                  end
    case commandSign do
      "+" -> newInitial = [packageFullName|initial]
              search(newInitial,seen,commands ++ [commandSign <> packageFullName],constraints,repo)

      "-" ->  newInitial = initial -- [packageFullName]
              search(newInitial,seen,commands ++ [commandSign <> packageFullName],constraints,repo)
    end
    
  end

  def meetConstraints?(initial,constraints,repo) do
   Enum.all?(constraints, fn constraint -> resolveConstraint(constraint,initial,repo) end)
  end

  def resolveConstraint(constraint,initial,repo) do
    constraintName = String.slice(constraint,1,String.length(constraint))
    case String.at(constraint,0) do
      "+" -> containsConstraint?(constraintName,initial,repo)
      "-" -> not containsConstraint?(constraintName,initial,repo)
      end
  end

  def containsConstraint?([],[]) do
    true
  end

  def containsConstraint?(constraint,initial,repo) do
      result = Enum.reduce_while(initial,{:error},fn pack, acc ->  
                                                package = findPackage(repo,pack)
                                                cond do
                                                String.contains?(constraint,">=") ->
                                                  [name,version] = String.split(constraint, ">=")

                                                  if package["name"] == name do
                                                    if ConflictResolver.versionCompare(package["version"],version) >= 0 do
                                                      {:halt, {:ok}}
                                                    else  
                                                      {:cont, {:error}}
                                                    end

                                                  else
                                                    {:cont, {:error}}
                                                  end



                                                String.contains?(constraint,"<=") ->

                                                  [name,version] = String.split(constraint, "<=")

                                                  if package["name"] == name do
                                                    if ConflictResolver.versionCompare(package["version"],version) <= 0 do
                                                     {:halt, {:ok}}
                                                    else  
                                                      {:cont, {:error}}
                                                    end
                                                  else
                                                    {:cont, {:error}}
                                                  end

                                                String.contains?(constraint,">") ->
                                                  [name,version] = String.split(constraint, ">")

                                                  if package["name"] == name do
                                                    if ConflictResolver.versionCompare(package["version"],version) > 0 do
                                                      {:halt, {:ok}}
                                                    else  
                                                      {:cont, {:error}}
                                                    end

                                                  else
                                                    {:cont, {:error}}
                                                  end
                                                String.contains?(constraint,"<") ->
                                                  [name,version] = String.split(constraint, "<")
                                                  if package["name"] == name do
                                                    if ConflictResolver.versionCompare(package["version"],version) < 0 do
                                                      {:halt, {:ok}}
                                                    else  
                                                      {:cont, {:error}}
                                                    end
                                                  else
                                                    {:cont, {:error}}
                                                  end

                                                  String.contains?(constraint,"=") ->
                                                  [name,version] = String.split(constraint, "=")
                                                  if package["name"] == name do
                                                    if package["version"] == version do
                                                      {:halt, {:ok}}
                                                    else  
                                                      {:cont, {:error}}
                                                    end
                                                  else
                                                    {:cont, {:error}}
                                                  end
                                               true -> 
                                                if package["name"] == constraint do
                                                  {:halt, {:ok}}
                                                else  
                                                  {:cont, {:error}}
                                                end 
                                              end
                                            end)
      case result do
                    {:error} -> false
                    _ -> true
      end

  end
  def seen?([],_) do
    false
  end

  def seen?(_,[]) do
    false
  end

  @doc """
   takes two lists of packages and check if all package in the first one   
   """ 
  def seen?(initial,seen) do
    Enum.all?(initial, fn package -> package in seen end)
  end

  def seen!(initial,seen) do
    (initial --seen) ++ seen
  end

  @doc """
    check if every package in the state is valid
  """
  def valid(initial,repo) do 
      Enum.all?(initial, fn package -> package = findPackage(repo,package)
                                       ConflictResolver.resolveConflicts(package,initial,repo) == {:ok} &&
                                       resolve(Map.get(package,"depends",[]),initial,repo) == {:ok} end)
  end
  
  def resolve([],_initial,_repo) do
        {:ok}
  end

  def resolve([dependencies|dependenciesList],initial,repo) do
    case resolveDependency(dependencies,initial,repo) do
        {:ok} -> resolve(dependenciesList,initial,repo)
        {:error} -> {:error}
      end
  end

  def resolveDependency([],_initial,_repo) do
    {:error}
  end
  @doc """
    take a dependency and see if it is matched
    if one of them fail, return {:error} otherwise return {:ok}
  """
  def resolveDependency([dependency| dependencies],initial,repo) do 
      result = Enum.reduce_while(initial,{:error},fn pack, acc ->  
                                                package = findPackage(repo,pack)
                                                cond do
                                                String.contains?(dependency,">=") ->
                                                  [name,version] = String.split(dependency, ">=")

                                                  if package["name"] == name do
                                                    if ConflictResolver.versionCompare(package["version"],version) >= 0 do
                                                      {:halt, {:ok}}
                                                    else  
                                                      {:cont, {:error}}
                                                    end

                                                  else
                                                    {:cont, {:error}}
                                                  end



                                                String.contains?(dependency,"<=") ->

                                                  [name,version] = String.split(dependency, "<=")

                                                  if package["name"] == name do
                                                    if ConflictResolver.versionCompare(package["version"],version) <= 0 do
                                                     {:halt, {:ok}}
                                                    else  
                                                      {:cont, {:error}}
                                                    end
                                                  else
                                                    {:cont, {:error}}
                                                  end

                                                String.contains?(dependency,">") ->
                                                  [name,version] = String.split(dependency, ">")

                                                  if package["name"] == name do
                                                    if ConflictResolver.versionCompare(package["version"],version) > 0 do
                                                      {:halt, {:ok}}
                                                    else  
                                                      {:cont, {:error}}
                                                    end

                                                  else
                                                    {:cont, {:error}}
                                                  end
                                                String.contains?(dependency,"<") ->
                                                  [name,version] = String.split(dependency, "<")
                                                  if package["name"] == name do
                                                    if ConflictResolver.versionCompare(package["version"],version) < 0 do
                                                      {:halt, {:ok}}
                                                    else  
                                                      {:cont, {:error}}
                                                    end
                                                  else
                                                    {:cont, {:error}}
                                                  end

                                                  String.contains?(dependency,"=") ->
                                                  [name,version] = String.split(dependency, "=")
                                                  if package["name"] == name do
                                                    if package["version"] == version do
                                                      {:halt, {:ok}}
                                                    else  
                                                      {:cont, {:error}}
                                                    end
                                                  else
                                                    {:cont, {:error}}
                                                  end
                                               true -> 
                                                if package["name"] == dependency do
                                                  {:halt, {:ok}}
                                                else  
                                                  {:cont, {:error}}
                                                end 
                                              end
                                            end)
      case result do
                    {:error} -> resolveDependency(dependencies,initial,repo)
                    _ -> {:ok}
      end
  end
  
  # prints to the stdout the commands
  def print(commands) do
    newCommands = Poison.encode!(commands)
    IO.puts newCommands
  end

end