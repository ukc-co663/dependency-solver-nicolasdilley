object ConstraintsParser {

  def parse (constrainAsString: String) : Constraint = {

    val install = constrainAsString.startsWith("+") // check whether its a remove or install constraint

    if (constrainAsString.contains('=')) // a version has been specified
    {
      val nameEnd = constrainAsString.indexOf('=') // the name finish when = starts
      new Constraint(install,constrainAsString.substring(1,nameEnd),constrainAsString.substring(nameEnd + 1))
    }
    else
    {
      new Constraint(install,constrainAsString.substring(1),"")
    }
  }
}
