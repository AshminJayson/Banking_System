import mysql.connector
from flask import Flask, request, render_template, redirect
import time
from datetime import datetime
datetime.today().strftime('%Y-%m-%d')


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
        try : 
            curr.execute('select passwordCheck(%s,%s)', [int(accno), password])
            validity = curr.fetchone()
            if validity[0] == 1:
                authtoken = 1
        except :
            return 'Invalid Input'

    if authtoken == 0:
        return render_template('login.html', valid = 'Please re-check the credentials')
    else:
        authtoken = 0
        return redirect('/' + accno)


@app.route('/<string:accno>')
def userdetails(accno):
    curr.execute('select * from transactions where sender_accno = %s', [int(accno)])
    transactions = curr.fetchall()
    curr.execute('select * from investments where accno = %s', [int(accno)])
    investments = curr.fetchall()
    curr.execute('select * from loans where accno = %s', [int(accno)])
    loans = curr.fetchall()
    curr.execute('select name from accounts where accno = %s', [int(accno)])
    name = curr.fetchone()

    return render_template('userdetails.html', transactions=transactions, investments=investments, loans=loans,accno=accno, name = name[0])

@app.route('/<string:accno>transact')
def transactPage(accno):
    return render_template('transact.html', accno=accno)

@app.route('/<string:accno>transact', methods=['POST'])
def transact(accno):
    if request.method == 'POST':
        raccno = request.form["raccno"]
        amount = request.form["amount"]
        date = datetime.today().strftime('%Y-%m-%d')

        try:
            curr.execute('insert into transactions values(null,%s,%s,%s,%s,null)', [int(accno), int(raccno),int(amount),date])
            curr.execute('commit')
        except:
            print('Database insertion error')


    return redirect('/' + accno)

    
if __name__ == '__main__':
    app.run(debug=True)
    curr.close()
    conn.close()