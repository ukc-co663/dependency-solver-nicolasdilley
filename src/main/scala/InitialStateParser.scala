import scala.collection.mutable

object InitialStateParser {

  def parse(initials:List[String]) : Map[String,String] = {
    (for(initial <- initials) yield {

      if(initial.contains('=')) {
        (initial.substring(0,initial.indexOf('=') - 1) -> initial.substring(initial.indexOf('=') + 1))
      }
      else {
        (initial -> "")
      }
    }) toMap
  }
}
