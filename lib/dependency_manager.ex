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
    |> resolveConstraints(parsedRepo,parsedInitial)
    |> print
    
  end

  @doc """
    Takes a list of constraints a repo and the initial state and a list of commands
  """
  def resolveConstraints(constraints,repo,initial) do

    # go through each constraints and return a list of commands to satisfy all the constraints 
    case List.foldl(constraints, {[],initial}, fn(constraint, {commands,initial}) -> {resolvedCommands , newInitial} = resolveConstraint(constraint,repo,initial) 
                                                                                  {commands ++ resolvedCommands,newInitial} end) do
      {commands,_} -> commands
      true -> []
    end
  end

  @doc """
    Take a constraint, the repository of all packages and the valid initial state
    and returns a tuple with a list of commands to satisfy the constraints and the new initial state with all the command edependencyecuted
  """
  def resolveConstraint(constraint,repo,initial) do 

    name = String.slice(constraint, 1..100)
    #find the package with name name
    package = findPackage(repo,name);

    if(String.at(constraint,0) == "+") do
     
      #install the package
      case resolveDependencies(package,initial,repo) do
        {:ok,commands,newInitial} -> {commands,newInitial} 
        {:error} ->  #This is where we need to uninstall some stuff
                    {[],[]}
      end
    else
        #we need to uninstall a package
    end 
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

  @doc """
    Resolve Dependencies takes a package and check if it can be installed with the initial state given 
    if it doesnt conflict with initial it will install all its dependencies until one succeeds
    if none succeeds return {:error}
  """
  @spec resolveDependencies(%{},[%{}],[%{}]) :: {:ok,[String],[%{}]} | {:error}
  def resolveDependencies(package,initial,repo) do

    packageFullName = Map.get(package,"name") <> "=" <> Map.get(package,"version")
    
    if(!Enum.member?(initial,packageFullName)) do
      
      #check that the package does not conflict with initial 
      if ConflictResolver.resolveConflicts(package,initial) == {:ok} do
        
        #loop through each dependencies and check if one of them returns :ok
        case Map.get(package,"depends",[]) do
          [] -> {:ok, ["+" <> packageFullName|[]],[packageFullName|initial]}
          dependenciesList -> 
            case Enum.find(dependenciesList, fn(dependencies) ->
              resolveDependency(dependencies,[],initial,repo)
               != {:error} end) do
            {:ok,newCommands,newInitial} -> {:ok, ["+" <> packageFullName|newCommands],[packageFullName |newInitial]}
            _ -> {:error}
            end
          end

      else
        {:error}
      end

    else
      {:ok, [],initial}
    end
        
  end

  def resolveDependency([],commands,initial,_repo) do
    {:ok,commands,initial}
  end

  @doc """
    take a list of dependencies and tries to install them all 
    if one of them fail, return {:error} otherwise return {:ok,newCommands,newInitial}
  """
  def resolveDependency([dependency| dependencies],commands,initial,repo) do
      
      case resolveDependencies(findPackage(repo,dependency),initial,repo) do
                    {:ok,newCommands,newInitial} -> resolveDependency(dependencies,commands ++ newCommands,newInitial,repo)
                    {:error}->{:error}
      end
  end
  
  # prints to the stdout the commands
  def print(commands) do
    newCommands = Poison.encode!(commands)
    IO.puts newCommands
  end

end
