/*
A processing sketch that uses OpenWeatherMap API to obtain data about a given city, and transmutates this information into a visual representation of the sky in a given location.
*/

/* SETUP PHASE
Establishes variables that will be used later.
*/

/* Instance variables used to manage the recording of frames. The program writes 1 frame to a directory called output, the 400th frame of the video. */
int r = 0;

/* Pollen object arrays to represent the clouds and rain. "Pollen" just means the pixelated dots we see onscreen. */
Pollen[] pollen;
Pollen[] rain;

/* Alpha is the transparancy of the background that fills every frame, allowing the pixels to leave trails. */
float alpha;

/* JSON Objects can read and parse APIs, json reads the weather API and json2 reads the time API. */
JSONObject json;
JSONObject json2;

/* *** IMPORTANT ***
The weather API strings are unchanged, the only thing that needs to be changed based on user input is the String city. This changes depending on the target city. Change this to any city name to have the weather wizard represent that city in the visual. For cities with a space in their name, replace the space with "+"
*/
String city = "Tokyo";
String weatherURL = "http://api.openweathermap.org/data/2.5/weather?q=Atlanta&appid=48f1269a0d96fb6682e998b9da66fa95";
String timeURL = "https://showcase.linx.twenty57.net:8081/UnixTime/tounixtimestamp?datetime=now";

/*Colors and a Colorer object to change the background of the sketch based on weather conditions parsed from the API. */
color bg;
Colorer myColorer;

/*Boolean rainfactor (ifRain) */
boolean rainFactor = false;

/*TextPlopper object to be used with text placement*/
textPlopper myTextPlopper;

/* Methods to get various outputs from the JSONObjects and API, including all weather info. These methods are used throughout the processing code to get these parameters, and use their values for various applications. */
int getClouds() {
    json = loadJSONObject(weatherURL.substring(0,49) + city + weatherURL.substring(56));
    JSONObject cloudsData = json.getJSONObject("clouds");
    int clouds = cloudsData.getInt("all");
    return clouds;
}

int getTemp() {
    JSONObject weatherData = json.getJSONObject("main");
    int temp = weatherData.getInt("temp");
    return temp;
}

int getHumidity() {
    JSONObject weatherData = json.getJSONObject("main");
    int humidity = weatherData.getInt("humidity");
    return humidity;
}

float getWindSpeed() {
    JSONObject windData = json.getJSONObject("wind");
    float windSpeed = windData.getInt("speed");
    return windSpeed;
}

int getSunrise() {
    JSONObject sysData = json.getJSONObject("sys");
    int sunrise = sysData.getInt("sunrise");
    return sunrise;
}

int getSunset() {
    JSONObject sysData = json.getJSONObject("sys");
    int sunset = sysData.getInt("sunset");
    return sunset;
}

int getTimezone() {
    int timezone = json.getInt("timezone");
    return timezone;
}

String getMainWeather () {
    JSONArray mainWeatherData = json.getJSONArray("weather");
    JSONObject mainWeatherDataObject = mainWeatherData.getJSONObject(0);
    String mainWeatherString = mainWeatherDataObject.getString("description");
    return mainWeatherString;
}

/* Returns a boolean to determine if it's raining in an area. */
boolean isRaining() {
    JSONArray mainWeatherData = json.getJSONArray("weather");
    JSONObject mainWeatherDataObject = mainWeatherData.getJSONObject(0);
    String mainWeatherString = mainWeatherDataObject.getString("main");
    if (mainWeatherString.equals("Rain")) {
        return true;
    } else {
        return false;
    }
}

/* The Processing setup method. This sets the stage for the sketch, drawing the dimensions with size, and placing the pollen particles */
void setup() {
    size (400, 200);
    //From black to a soft blue, depending on time of day at given location.
    background (0);
    noStroke();
    //smooth(5); //Possible smoothing function later
    placePollen();
    if (isRaining()) {
        placeRain();
        rainFactor = true;
    }
    bg = color(255, 0, 0);
    myColorer = new Colorer(bg);
    myTextPlopper = new textPlopper(getMainWeather(), getTemp(), getWindSpeed(), getClouds());
}

/* This is the "main" method, which draws a new frame every frame, at the framerate which is set by the wind speed of the area. The methods for the pollen for both rain and clouds are called, which move the pixels each frame. Also, the textPlace method is used to display the weather information in the upper left hand corner of the sketch.
*/
void draw() {
    frameRate(map(getWindSpeed(), 0.0, 100.0, 18.0, 45.0));
    alpha = map(400, 0, width, 5, 30);
    fill(myColorer.getColor(), alpha);
    rect(0, 0, 400, 200);
    loadPixels();
    for (Pollen p : pollen) {
        p.go();
    }
    if (rainFactor){
        for (Pollen r : rain) {
            r.goRain();
        }
    }
    updatePixels();
    textPlace();
    r++;
    if (r == 400) {
        saveFrame("output/ww.png");
    }
}

/* Places text on the screen to match the weather parameters of the location. */
void textPlace() {
    fill (255, 255, 255);
    text(city, 10, 15);
    text(myTextPlopper.getOne(), 10, 30);
    text("Temp: " + (int)((myTextPlopper.getTwo() - 273.15) * 9/5 + 32) + "F", 10, 45);
    text("Wind Speed: " + myTextPlopper.getThree() + "m/s", 10, 60);
    text("Clouds: " + myTextPlopper.getFour() + "%", 10, 75);
}


/* The place pollen method uses the cloud coverage of the location to determine the amount of particles to use. */
void placePollen() {
    color c = color(255, 255, 255);
    int pollenCount = (int) (map(getClouds(), 0, 100, 0, 10000));
    pollen = new Pollen[pollenCount];
    for (int i = 0; i < pollenCount; i++) {
        float x = random(width);
        float y = random(height);
        pollen[i] = new Pollen(x, y, c);
    }
}

/* Places rain particles if called. Uses cloud coverage to scale number of particles as well. */
void placeRain() {
    color c = color(173, 216, 230);
    int rainCount = (int) (map(getClouds(), 0, 100, 0, 2000));
    rain = new Pollen[rainCount];
    for (int i = 0; i < rainCount; i++) {
        float x = random(width);
        float y = random(height);
        rain[i] = new Pollen(x, y, c);
    }
}

/* The pollen class, containing the pollen constructor and the methods that the rain and clouds use to move, including displaying the actual particles by coloring the particular pixels. */
class Pollen {
    float positionX;
    float positionY;
    float wobble;
    float motion;
    float waveinessX;
    float waveinessY;
    color c;

    /* Pollen constructor. Takes in an x and y location, and a color c */
    Pollen(float positionX, float positionY, color c) {
        this.positionX = positionX;
        this.positionY = positionY;
        this.c = c;
    }

    /* The go() method is just three other methods in one. */
    public void go() {
        updatePosition();
        displayPollen();
        wrapPollen();
    }

    /* A seperate go() for the different rain behavior. */
    public void goRain() {
        updateRainPosition();
        displayPollen();
        wrapPollen();
    }

    /* Uses some "math" or something to determine the way in which the particles move onscreen. For rain, the movement is linear and consistent.*/
    void updateRainPosition() {
        wobble += .009;
        waveinessX = .002;
        waveinessY = .002;
        motion = noise(positionX * waveinessX, positionY * waveinessY, wobble);
        positionX += 2 * (motion);
        positionY += 2 * (motion);
    }

    /* The move method for the standard pollen, AKA, the clouds. This uses some more radial motion to emulate clouds drifting. */
    void updatePosition() {
        //Larger value is more uniform
        wobble += .009;
        //Larger is waveyer****?
        waveinessX = .002;
        waveinessY = .002;
        motion = noise(positionX * waveinessX, positionY * waveinessY, wobble) * TWO_PI;
        positionX += 2 * cos(motion);
        positionY += 2 * sin(motion);
    }

    /* This method tells the sketch to color the individual pixel where the pollen is "located" a certain color. */
    void displayPollen() {
        if (this.positionX > 0 && this.positionX < width && this.positionY > 0 && this.positionY < height) {
            pixels[(int)positionX + (int)positionY * width] = c;
            //ellipse(this.positionX, this.positionY, 3, 3);
        }
    }

    /* This just resets a pollen particle so the sketch loops, and so the particles don't just drift offscreen. */
    void wrapPollen() {
        if (positionX < 0) positionX = width;
        if (positionX > width) positionX = 0;
        if (positionY < 0) positionY = height;
        if (positionY > height) positionY = 0;
    }
}

/* The colorer class. The colorer is what determines the background and the color of the background based on the time of day and weather. */
class Colorer {
    color c;

    /* A colorer constructor, which takes in a color and reassigns it based on the time of day and weather. Uses RED as a fallback, so if the background is ever red, we know we missed a weather case. */
    Colorer(color c) {
        json2 = loadJSONObject(timeURL);
        //Obtains the current time in UNIX time.
        int currentTimeUTC = (json2.getInt("UnixTimeStamp"));
        /* The nighttime case, or the "after sunset" case. Different shades for different weathers at night than during the day. */
        if (currentTimeUTC > getSunset() || currentTimeUTC < getSunrise()) {
            switch (getMainWeather()) {

                case "moderate rain":
                case "heavy intensity rain":
                case "very heavy rain":
                case "extreme rain":
                case "freezing rain":
                case "light intensity shower rain":
                case "heavy intensity shower rain":
                case "ragged shower rain":
                case "light rain":
                case "mist":
                case "rain": this.c = color(64,64,64);
                break;

                case "shower rain": this.c = color(104, 104, 104);
                break;

                case "thunderstorm": this.c = color(0, 0, 0);
                break;

                case "clear sky": this.c = color(0, 0, 128);
                break;

                //Less cloudy
                case "few clouds": this.c = color(0,0,77);
                break;

                //More clouds
                case "scattered clouds": this.c = color(0, 0, 26);
                break;

                //Most clouds
                case "broken clouds": this.c = color(0, 0, 26);
                break;

                case "overcast clouds": this.c = color(8, 8, 8);
                break;

                case "light snow":
                case "Heavy snow":
                case "Sleet":
                case "Light shower sleet":
                case "Shower sleet":
                case "Light rain and snow":
                case "Rain and Snow":
                case "Light shower snow":
                case "Shower snow":
                case "Heavy shower snow":
                case "snow": this.c = color(0, 0, 26);
                break;

                default: this.c = color(255, 0, 0);
                break;

            }
        /* The daytime case and all the possible daytime shades. */
        } else if (currentTimeUTC < getSunset()) {
            switch (getMainWeather()) {

                case "moderate rain":
                case "heavy intensity rain":
                case "very heavy rain":
                case "extreme rain":
                case "mist":
                case "freezing rain":
                case "light intensity shower rain":
                case "heavy intensity shower rain":
                case "ragged shower rain":
                case "light rain":
                case "rain": this.c = color(119,136,153);
                break;

                case "shower rain": this.c = color(119, 136, 153);
                break;

                case "thunderstorm": this.c = color(105, 105, 105);
                break;

                case "clear sky": this.c = color(137, 207, 240);
                break;

                case "few clouds": this.c = color(0,128,255);
                break;

                case "scattered clouds": this.c = color(176,196,222);
                break;

                case "broken clouds": this.c = color(118, 153, 188);
                break;

                case "overcast clouds": this.c = color(160, 160, 160);
                break;

                case "light snow":
                case "Heavy snow":
                case "Sleet":
                case "Light shower sleet":
                case "Shower sleet":
                case "Light rain and snow":
                case "Rain and Snow":
                case "Light shower snow":
                case "Shower snow":
                case "Heavy shower snow":
                case "Snow": this.c = color(211,211,211);
                break;

                default: this.c = color(255, 0, 0);
                break;

            }
        } else {
            this.c = color(255, 0, 0);
        }
    }

    color getColor() {
        return this.c;
    }

}

/* textPlopper is an object that stores values that will later be printed as the information data. */
class textPlopper {

    String one;
    int two;
    float three;
    int four;

    textPlopper(String one, int two, float three, int four) {
        this.one = one;
        this.two = two;
        this.three = three;
        this.four = four;
    }

    String getOne() {
        return this.one;
    }

    int getTwo() {
        return this.two;
    }

    float getThree() {
        return this.three;
    }

    int getFour(){
        return this.four;
    }

}
