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




@app.route("/")
def login():
    return render_template('login.html', valid='')

@app.route("/", methods = ['POST','GET'])
def loginverify():


    if request.method == 'POST':
        accno = request.form["accno"]
        password = request.form["password"]
        try : 
            curr.execute('select passwordCheck(%s,%s)', [int(accno), password])
            validity = curr.fetchone()
            if validity[0] == 1:
                return redirect('/' + str(accno))
            else:
                return render_template('login.html', valid = 'Please re-check the credentials')
        except :
            return render_template('login.html', valid = 'Invalid Input')





@app.route('/<int:accno>')
def userdetails(accno):
    curr.execute('select balance, min_balance from balance_details where accno = %s', [int(accno)])
    bldetails = curr.fetchone()
    curr.execute('select * from transactions where sender_accno = %s', [int(accno)])
    transactions = curr.fetchall()
    curr.execute('select * from investments where accno = %s', [int(accno)])
    investments = curr.fetchall()
    curr.execute('select * from loans where accno = %s', [int(accno)])
    loans = curr.fetchall()
    curr.execute('select name from accounts where accno = %s', [int(accno)])
    name = curr.fetchone()
    print(bldetails)

    return render_template('userdetails.html', bldetails = bldetails, transactions=transactions, investments=investments, loans=loans,accno=accno, name = name[0])

@app.route('/<int:accno>transact')
def transactPage(accno):
    return render_template('transact.html', accno=accno)

@app.route('/<int:accno>transact', methods=['POST'])
def transact(accno):
    if request.method == 'POST':
        raccno = request.form["raccno"]
        amount = request.form["amount"]
        date = datetime.today().strftime('%Y-%m-%d')

        try:
            curr.execute('insert into transactions values(null,%s,%s,%s,%s,null)', [int(accno), int(raccno),int(amount),date])
            curr.execute('commit')
        except mysql.connector.Error as err:
            print(err)

        return redirect('/' + str(accno))

@app.route('/<int:accno>openinvestment')
def investmentpage(accno):
    return render_template('investment.html', accno = accno, status = '')

@app.route('/<int:accno>openinvestment', methods=['POST'])
def investmentopen(accno):
    if request.method == 'POST':
        amount = request.form["amount"]
        mdate = request.form["mdate"]
        cdate = datetime.today().strftime('%Y-%m-%d')

        try :
            curr.execute('select openInvestment(%s,%s,%s,%s)', [accno,int(amount),mdate,cdate])
            if curr.fetchone()[0] == 0:
                print('You do not have sufficient funds to do so')
                return render_template('investment.html', accno = accno, status = 'You do not have sufficient funds in your account to make the investment')
            else:
                curr.execute('commit')
                return redirect('/' + str(accno))
        except mysql.connector.Error as err:
            print(err)
    
    return 'hello'

@app.route('/<int:accno>+<int:investmentid>investment', methods = ['POST'])
def closeinvestment(accno, investmentid):
    if request.method == 'POST':
        curr.execute('delete from investments where investment_id = %s', [investmentid])
        curr.execute('commit')
        return redirect('/' + str(accno))

@app.route('/<int:accno>+<int:loanid>loan', methods=['POST'])
def repayLoan(accno, loanid):
    if request.method == 'POST':
        try:
            curr.execute('select repayLoan(%s,%s)', [accno, loanid])
            if curr.fetchone()[0] == 0:
                print('You do not have sufficient funds to do so')
            else:
                curr.execute('commit')
                return redirect('/' + str(accno))
        except mysql.connector.Error as err:
            print(err)

    return 'hello'


if __name__ == '__main__':
    app.run(debug=True)
    curr.close()
    conn.close()