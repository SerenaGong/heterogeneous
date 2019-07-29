import java.io.BufferedReader;
import java.io.Console;
import java.io.FileReader;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.util.Scanner;

public class AppAnalyse {

	public static void main(String args[]) throws Exception{
		ArrayList<String> exList =  new ArrayList<String>();
		BufferedReader exceptions  = new BufferedReader(new FileReader("exceptions.keys"));
		String str;
		while ((str = exceptions.readLine()) != null) {
			exList.add(str.toUpperCase());
		}
		
		Scanner scanner = new Scanner(System.in);
for(String x : exList) {

	if(scanner.toString().toUpperCase().contains(x)){
		System.out.println("Known Error Found: "+ scanner);
        }
    }
scanner.close();
	}

}

