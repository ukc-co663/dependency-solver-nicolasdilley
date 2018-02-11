import scala.collection.JavaConverters._

object Solver  extends App{


  // parse files
  val packageParser = new PackageParser(args)

  // parse initial state

  val initialState = InitialStateParser.parse(packageParser.initial.asScala.toList)

  // the list of all the commands to perfom in order reach the valid state required
  // parse constraints

  val constraints = packageParser.constraints.asScala.toList

  val commands = for(constraintAsString <- constraints) yield
    {
      ConstraintsParser.parse(constraintAsString)
    }

  resolveConstraints(commands)

  def resolveConstraints(constraints : List[Constraint]) : List[Constraint] = {
    val commandsList = for(constraint <- constraints) yield {
      resolveConstraint(constraint)
    }
    commandsList.flatten
  }


  def resolveConstraint(constraint : Constraint) : List[Constraint] = {
    // find the repo to install or remove
    val repo = packageParser.repos.asScala.toList.find( _.getName == constraint.packageName).get

    if(repo == null) {throw new Exception}

    println("Resolving Constraint : " + constraint.install);
    if(constraint.install)
      {
        resolveInstallation(repo,Nil)
      }
    else
      {
        resolveErase(repo)
      }
  }

  def resolveErase(repo: Package) : List[Constraint]= {
     if(repo.getDepends.asScala.toList.forall(depencies => depencies.isEmpty))
       {
          // there are no dependencies
         //
         Nil
       }
    Nil
  }
  def resolveInstallation(repo: Package, conflicts: List[String]) : List[Constraint] = {

    var toReturn = List[Constraint]()

    if(repo.getDepends.asScala.forall(e => e.isEmpty)) {
      // there are no dependencies
      if (!repo.getConflicts.contains(conflicts)) {
        // install the package
        assert(!initialState.contains(repo.getName));
        toReturn ::= new Constraint(true,repo.getName,repo.getVersion)
      }
      else {
          return null // it conflict returns null we cant install this repo
      }
    }
    else {


      var x = 0
      var foundDependencyPath = false
      val dependencies = repo.getDepends.asScala.toList

       while(!foundDependencyPath && x < dependencies.length)
         {
           val filteredDependencies = dependencies(x).asScala.toList.filter(name => initialState.contains(name)) // we don't need to install dependencies that are already installed

           var y = 0
           var continue = true

           while(continue && y < filteredDependencies.length)
           {
             val commandList = resolveInstallation(packageParser.repos.asScala.toList.find(p => p.getName == filteredDependencies(y)).get,conflicts ::: repo.getConflicts.asScala.toList)

             if(commandList != null){
              toReturn :::= commandList // add the new command list to our list
               y = y + 1 // no y++ in Scala :(
             }
             else {
                continue = false // break this branch will not work
             }
           }

           foundDependencyPath = continue
           x = x + 1
         }

      if(!foundDependencyPath)
        {
          return null
        }
    }
    toReturn
  }

}
