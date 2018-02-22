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
    parsedConstraints
    |> search([],[],parsedRepo,parsedInitial)
    |> print
    
  end

  def findPackage([repo|repos],name) do
      if Map.get(repo,"name") == name do
        repo 
      else 
        findPackage(repos,name)
      end
  end

  def findPackage([],_) do
    {:error}
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
                    case !meetConstraints?(initial,constraints) do
                          false -> commands
                          true ->
                              # this initial state does not meet the constraints so lets add another one and recurse
                              addAnotherPackageAndRecurse(initial,newSeen,commands,constraints,repo)
                    end
                  end
    end            
  end

  def addAnotherPackageAndRecurse(_,_,_,_,[]) do
    {:error}
  end

  def addAnotherPackageAndRecurse(initial,seen,commands,constraints,[package|repo]) do
    packageName = Map.get(package,"name")
    packageFullName = Map.get(package,"name") <> "=" <> Map.get(package,"version")
    commandSign = case packageFullName in initial do
                     false -> "-"
                     _ -> "+"
                  end
                      
    search([packageFullName|initial],seen,[commandSign <> packageName|commands],constraints,repo)
    addAnotherPackageAndRecurse(initial,seen,commands,constraints,repo)
  end


  def meetConstraints?(initial,constraints) do
    Enum.all?(constraints, fn constraint -> resolveConstraint(constraint,initial)end)
  end

  def resolveConstraint(constraint,initial) do
    constraintName = String.slice(constraint,1,String.length(constraint))

    case String.at(constraintName,0) do
      "+" -> containsConstraint?(constraintName,initial)
      "-" -> !containsConstraint?(constraintName,initial)
      end
  end

  def containsConstraint?(_,[]) do
    false
  end

  def containsConstraint?(constraint,[package|initial]) do
      splitName = String.split(package,"=")

      case !(constraint in splitName) do
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
      Enum.all?(initial, fn package -> ConflictResolver.resolveConflicts(findPackage(repo,package),initial) == {:ok} &&
                                      resolve(Map.get(findPackage(repo,package),"depends"),initial,repo) == {:ok} end)
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
    take a list of dependencies and tries to install them all 
    if one of them fail, return {:error} otherwise return {:ok,newCommands,newInitial}
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
