
import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.TypeReference;
import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.util.List;

public class JavaPackageParser {

    private List<Package> repos; // the initials repositories
    private List<String> initial; // what programs are already installed
    private List<String> constraints; // the constraints (what are needed to be installed and what need to be removed)

    public JavaPackageParser(String[] args) {
        try {
            TypeReference<List<Package>> repoType = new TypeReference<List<Package>>() {
            };
            List<Package> repo = JSON.parseObject(readFile(args[0]), repoType);
            TypeReference<List<String>> strListType = new TypeReference<List<String>>() {
            };
            List<String> initial = JSON.parseObject(readFile(args[1]), strListType);
            List<String> constraints = JSON.parseObject(readFile(args[2]), strListType);
        }
        catch(IOException e)
        {
            e.printStackTrace();
        }
    }

    public List<Package> getRepos()
    {
        return repos;
    }

    public List<String> getInitial()
    {
        return initial;
    }

    public List<String> getConstraints()
    {
        return constraints;
    }

    public String readFile(String filename) throws IOException {
        BufferedReader br = new BufferedReader(new FileReader(filename));
        StringBuilder sb = new StringBuilder();
        br.lines().forEach(line -> sb.append(line));
        return sb.toString();
    }
}
