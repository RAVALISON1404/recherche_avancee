export CLASSPATH=/home/ravalison/Documents/lib/servlet-api.jar:$CLASSPATH
export CLASSPATH=/home/ravalison/Documents/lib/postgresql-42.5.1.jar:$CLASSPATH
cp /home/ravalison/Documents/lib/postgresql-42.5.1.jar ./webapp/WEB-INF/lib
cp /home/ravalison/Documents/lib/servlet-api.jar ./webapp/WEB-INF/lib
export CLASSPATH=./webapp/WEB-INF/classes:$CLASSPATH
javac -d ./webapp/WEB-INF/classes ./**/*.java
javac -d ./webapp/WEB-INF/classes ./**/**/*.java -parameters
cd ./webapp || exit
jar cvf /home/ravalison/App/apache-tomcat-10.1.9/webapps/recherche.war ./