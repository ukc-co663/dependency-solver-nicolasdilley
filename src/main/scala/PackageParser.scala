
import com.alibaba.fastjson.{JSON, TypeReference}
import java.io.BufferedReader
import java.io.FileReader
import java.io.IOException
import java.util
import java.util.List

class PackageParser (val args: Array[String])
{

      val repos: util.List[Package] = JSON.parseObject(readFile(args(0)), new TypeReference[List[Package]](){})
      val initial: util.List[String] = JSON.parseObject(readFile(args(1)), new TypeReference[List[String]](){})
      val constraints: util.List[String] = JSON.parseObject(readFile(args(2)), new TypeReference[List[String]](){})


  @throws(classOf[IOException])
  def readFile(filename: String) : String = {
    val br = new BufferedReader(new FileReader(filename))
    val sb = new StringBuilder()
    br.lines().forEach(line => sb.append(line))
    sb.toString()
  }
}
