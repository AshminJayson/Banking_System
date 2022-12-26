import mysql.connector
import time
from flask import Flask, render_template, request

class dbConnection:
    def __init__(self):

        self.conn = mysql.connector.connect(        
        host = "localhost",
        username = "root",
        password = "DAMN*you4",
        database = "bankingsystem",
        )

        self.curr = self.conn.cursor()

        print('Connection to db has been established successfully')


    def verifyLogin(self, accno, password):
        execStatement = "select password from user where accno = %s"
        self.curr.execute(execStatement, [int(accno)])
        validPassword = self.curr.fetchone()[0]

        res =  True if password == validPassword else False
        return res


    def __del__(self):
        self.curr.close()
        self.conn.close()
        print('Connection to db has been terminated successfully')



app = Flask(__name__)
@app.route("/")
def hello():
    return render_template('login.html')

@app.route("/login", methods = ['POST', 'GET'])
def login():
    if request.method == 'POST':
        accno = request.form["accno"]
        password = request.form["password"]
        dbObj = dbConnection()
        state = dbObj.verifyLogin(accno,password)

    if state == True:
        return 'Successful'
    else:
        return 'Unsuccesful'


if __name__ == "__main__":
    app.run(debug=True)


