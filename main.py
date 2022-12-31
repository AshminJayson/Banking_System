import mysql.connector
from flask import Flask, request, render_template
import time


try :
    conn = mysql.connector.connect(
            host = "localhost",
            username = "bankadmin",
            password = "bankadmin",
            database = "bankingsystem",
    )

    curr = conn.cursor()

    print('Connection to DB has been established')
except:
    print('Connection to the DB has failed')




app = Flask('__name__')


authtoken = 0

@app.route("/")
def login():
    global authtoken
    authtoken = 0
    return render_template('login.html', valid='')

@app.route("/", methods = ['POST','GET'])
def loginverify():

    global authtoken
    if request.method == 'POST':
        accno = request.form["accno"]
        password = request.form["password"]
        curr.execute('select passwordCheck(%s,%s)', [int(accno), password])
        validity = curr.fetchone()
        if validity[0] == 1:
            authtoken = 1

    if authtoken == 0:
        return render_template('login.html', valid = 'Please re-check the credentials')
    else:
        authtoken = 0
        return 'happy banking'


if __name__ == '__main__':
    app.run(debug=True)