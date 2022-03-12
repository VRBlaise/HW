from flask import Flask, json, render_template, request
import os

#create instance of Flask app
app = Flask(__name__)

#decorator
@app.route("/")
def echo_hello():
    return "<p>Hello World!</p>"

@app.route("/all")
def nobel():  # Read nobeljson file
    json_url = os.path.join(app.static_folder,"","nobel.json")
    data_json = json.load(open(json_url))
    render_template('index.html',data=data_json)

    return data_json

@app.route("/<year>")
def nobel_year(year): # get data for the given year
    json_url = os.path.join(app.static_folder,"","nobel.json")
    data_json = json.load(open(json_url))

    data = data_json['prizes']
    year = request.view_args['year']
#condition to check for year
    output_data = [x for x in data if x['year']>=year]
    render_template('index.html',data=output_data)
    data_json['prizes'] = output_data
    return data_json




# Form to add nobel prize details
@app.route('/add')
def addPrize():
    return render_template('addnewnobel.html')
# method to save newly added nobel prize details to nobel.json
@app.route('/save', methods=['POST'])
def save():
    data = {}
    member = {}
    members = []
    # Getting data from the form
    data['category'] = request.form['category']
    data['year'] = request.form['year']
    member['id'] = request.form['member_id']
    member['firstname'] = request.form['first_name']
    member['lastname'] = request.form['last_name']
    member['motivation'] = request.form['motivation']
    member['share'] = request.form['share']
    members.append(member)
    #Appending data to the nobel.json
    data['laureates'] = members
    json_url = os.path.join(app.static_folder,"","nobel.json")
    data_json = json.load(open(json_url))
    prizes = data_json["prizes"]
    prizes.append(data)
    data_json["prizes"] = prizes

# Read and update data to nobel.json file.
    a_file = open(json_url, "r")
    json_object = json.load(a_file)
    a_file.close()
    json_object = data_json

    a_file = open(json_url, "w")
    json.dump(json_object, a_file)
    a_file.close()
    return render_template('index.html',data=json_object)



if __name__ == "__main__":
    app.run(debug=True)