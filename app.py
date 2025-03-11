from flask import Flask

app = Flask(__name__)

@app.route('/')
def home():
    return '''  <html>
                <head>
                <title> CI/CD-Assignment </title>
                </head>
                <body>
                <h1> Automated Container Deployment and Administration in the Cloud </h1>
                <h2> Docker is built and running </h2>
                </body>
                </html>'''

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
