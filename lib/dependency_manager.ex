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
    
    print(addAnotherPackageAndRecurse(parsedInitial,[],[],parsedConstraints,parsedRepo,parsedRepo))  
  end

  def findPackage([],_) do
    {:error}
  end

  def findPackage([repo|repos],name) do
      cond do
        String.contains?(name,">") ->
          [name,version] = String.split(name, ">")
          if Map.get(repo,"name") == name do
                  repo 
                else 
                  findPackage(repos,name)
                end
          
        String.contains?(name,"<") ->
          [name,version] = String.split(name, "<")
          if Map.get(repo,"name") == name do
                  repo 
                else 
                  findPackage(repos,name)
                end
        String.contains?(name,">=") ->
          [name,version] = String.split(name, ">=")

          if Map.get(repo,"name") == name do
                  repo 
                else 
                  findPackage(repos,name)
                end

        String.contains?(name,"<=") ->
          [name,version] = String.split(name, "<=")
          if Map.get(repo,"name") == name do
                  repo 
                else 
                  findPackage(repos,name)
                end
        String.contains?(name,"=") ->
          [name,version] = String.split(name, "=")
          if Map.get(repo,"name") == name do
                  repo 
                else 
                  findPackage(repos,name)
            end
        true -> 
                if Map.get(repo,"name") == name do
                  repo 
                else 
                  findPackage(repos,name)
                end
    end
  end

  


  def search(initial,seen,commands,constraints,leftToParse,repo) do
    
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
                    case !meetConstraints?(initial,constraints) do
                          false -> commands
                          true ->
                              # this initial state does not meet the constraints so lets add another one and recurse
                              addAnotherPackageAndRecurse(initial,newSeen,commands,constraints,repo,repo)
                    end
                  end
    end            
  end

  def addAnotherPackageAndRecurse(_,_,_,_,[],_) do
    {:error}
  end

  def addAnotherPackageAndRecurse(initial,seen,commands,constraints,[package|leftToParse],repo) do
    IO.inspect package["name"]
    packageFullName = package["name"] <> "=" <>package["version"]
    
    commandSign = case packageFullName in initial do
                     false -> "+"
                     _ -> "-"
                  end
    case commandSign do
      "+" -> newInitial = [packageFullName|initial]
              result = search(newInitial,seen,commands ++ [commandSign <> packageFullName],constraints,leftToParse,repo)
              if  result != {:error} do
                # add the commands needed to arrive to search plus the commands and return initial
                result
              else
                  addAnotherPackageAndRecurse(initial,seen,commands,constraints,leftToParse,Enum.shuffle(repo))
              end
      "-" ->  newInitial = initial -- [packageFullName]
              result = search(newInitial,seen,commands ++ [commandSign <> packageFullName],constraints,leftToParse,repo)
              if  result != {:error} do
                # add the commands needed to arrive to search plus the commands and return initial
                result
              else
                  addAnotherPackageAndRecurse(initial,seen,commands,constraints,leftToParse,Enum.shuffle(repo))
              end
    end
    
  end

  def meetConstraints?(initial,constraints) do
    Enum.all?(constraints, fn constraint -> resolveConstraint(constraint,initial)end)
  end

  def resolveConstraint(constraint,initial) do
    constraintName = String.slice(constraint,1,String.length(constraint))
    case String.at(constraint,0) do
      "+" -> containsConstraint?(constraintName,initial)
      "-" -> not containsConstraint?(constraintName,initial)
      end
  end

  def containsConstraint?(_,[]) do
    false
  end

  def containsConstraint?(constraint,[package|initial]) do
      splitName = String.split(package,"=")
      {:ok, name} = Enum.fetch(splitName,0)

      case (constraint == name) do
        false -> containsConstraint?(constraint,initial)
        _-> true
      end

  end

  @doc """
   takes two lists of packages and check if all package in the first one 
  
   """ 
  def seen?(initial,seen) do
    Enum.all?(initial, fn package -> package in seen end)
  end

  def seen!(initial,seen) do
    (initial -- seen) ++ seen
  end

  @doc """
    check if every package in the state is valid
  """
  def valid(initial,repo) do 
      Enum.all?(initial, fn package -> {:ok ,name} = Enum.fetch(String.split(package,"="),0)
                                      package = findPackage(repo,name)
                                      ConflictResolver.resolveConflicts(package,initial,repo) == {:ok} &&
                                      resolve(Map.get(package,"depends",[]),initial,repo) == {:ok} end)
  end
  
  def resolve([],_initial,_repo) do
        {:ok}
  end

  def resolve([dependencies|dependenciesList],initial,repo) do
    
    case resolveDependency(dependencies,initial,repo) do
        {:ok} -> resolve(dependenciesList,initial,repo)
        {:error} -> false
      end
  end

  def resolveDependency([],_initial,_repo) do
    {:error}
  end

  @doc """
    take a dependency and tries to install them all 
    if one of them fail, return {:error} otherwise return {:ok}
  """
  def resolveDependency([dependency| dependencies],initial,repo) do 
      package = findPackage(repo,dependency)
      packageFullName = Map.get(package,"name") <> "=" <> Map.get(package,"version")
      
      case packageFullName in initial do
                    false -> resolveDependency(dependencies,initial,repo)
                    true -> {:ok}
      end
  end
  
  # prints to the stdout the commands
  def print(commands) do
    newCommands = Poison.encode!(commands)
    IO.puts newCommands
  end

end
