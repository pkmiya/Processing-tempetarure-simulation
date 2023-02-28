// TWO DIMENSIONAL TEMPERATURE SIMULATION v1.7
// Created in a college subject Information Processing (Grade 3, year-round)
// [AUTHOR] YUSAKU MIYATA

// 2023-03-01 v1.7		Comment revised
// 2020-11-16 v1.6.2	Assignment submitted

// PRESENTATION
/*
  0-1. 境界を右クリックすることで境界の温度(0/300[℃])を変更可能
  0-2. マウスホイールの回転でシミュレーションの拡大率を変更可能

  1. 左クリック・ドラッグで，その場所の温度を変化させる
    A. 温度変化のモード(加熱/冷却)は「T」(TOGGLE)ボタンで切り替え可能
    B. 加熱/冷却温度は↑/↓キーで調整可能(初期温度: +1000[℃]，間隔: 10[℃]，範囲: [-1000, 1000])
  2. 熱源の状態を変化させる
    A. 熱源は半径 10，中心をシミュレーション中心部にもつ真円
    B. 熱源の存在は「E」(EXIST)キーで切り替え可能
    C. 温度は←/→キーで調整可能(初期温度: +200[℃]，間隔: 10[℃]，範囲: [-1000, 1000])
    D. 半径は1/2キーで調整可能(初期半径: 10，間隔: 1，範囲: [1, 40])
  3. 「R」(RESET)キーでシミュレーションをリセット
  4. 経過時間および上記の温度情報を，画面上に表示

*/

int N = 84;				// No. of cells in a row
int M = 120;			// No. of cells in a column

int XOrig = 10;		// X coordinate of Origin on simulation
int YOrig = 45;		// Y coordinate of Origin on simulation
float mag = 5;		// Size of a single cell

float [][] src = new float[N + 2][M + 2];
float [][] dst = new float[N + 2][M + 2];

int times = 5; 		// times of executing step() function
float lambda = 0.001;  // thermal diffusivity λ [m^2/sec]
float dt = 1.0/300.0;  // time     Δt [sec]
float dx = 0.005;      // distance Δx [m]

// Manual heating/cooling (H/C) control with right mouse dragging/clicking
// The temeprature can be adjusted with upper/lower arrow
int heating_deg;        									// H/C temperature (Default: 1000)
int heating_mode = 1;   									// H/C mode toggle (Default: 1 (Heating))
String status[] = {"Cooling", "Heating"};	// H/C mode text

// Elapsed time since simulation started
int ref_ms = 0; int start_ms = 0;
int m = 0, s = 0, ms = 0;

// Circular heating source settings
// The temeprature can be adjusted with left/right arrow
int source_deg;	// Temperature	(Default: 200)
int r; 			    // Radius				(Default: 10)
int exist;			// Toggle the source (Default: 1 (exist))

void setup() {
  size(640, 500);
  noStroke();
  
  reset_s();
}

void draw() {
  background(0);
  DrawThermoBar();
  for(int i = 1; i <= times; i++){
    step();
  }
  DrawAllCell(src);
  fill(255);
  
  // Basic info
  text("Thermal simulation by pkmiya", 450, 480);    // Work name
  text("TwoDimensionalTemperatureSimulation.pde", 15, 480);                // File name
  text("「R」to reset simulation", 250, 480);        // Additional help
  text("FrameRate: " + nf(frameRate, 2, 1), 500, 10);// Framerate

  // Calc & diplay elapsed time
  ref_ms = millis() - start_ms;
  ms = ref_ms % 1000;
  if(ms >= 1) s = (ref_ms - ms) / 1000;  
  text("Elapsed time: " + nf(s, 3) + ":" + nf(ms, 3), 350, 10);

  // Heating status & Help
  text("Mode: " + status[heating_mode] + ", temperature: " + heating_deg + "[℃] (T or ↑/↓)", 10, 27);
  text("Source temperature: " + source_deg + "[℃] (←/→), radius: " + r + "  (1/2)", 300, 27);

  if(frameCount == 10) save("3MI38-10-1_0.PNG");
}

// ======================================
// MAIN CALCULATION
// ======================================

// INITIALIZE : Initialize all cell data (with default temperature)
void InitCell(float [][] data) {
  // Initialize boundaries
  for (int i = 1; i <= N; i++) {
    data[i][0] = 300.0;							// LEFT WALL
    data[i][M+1] = 0.0;							// RIGHT WALL
  }
  for (int j=1; j<=M; j++) {
    data[0][j] = 0.0;								// UPPER WALL
    data[N+1][j] = 0.0;							// LOWER WALL
  }

  // Initialize non-boundaries
  for (int i = 1; i <= N / 2; i++) {
    for (int j = 1; j <= M / 2; j++) {
      if((sq((int)i-42.0))+(sq((int)j-60.0)) <= sq((int)r) && exist == 1) data[i][j] = source_deg;
      else data[i][j] = 150.0;
    }
    for(int j = M / 2; j <= M; j++){
      if((sq((int)i-42.0))+(sq((int)j-60.0)) <= sq((int)r) && exist == 1) data[i][j] = source_deg;
      else data[i][j] = 100;
    }
  }
  for (int i = N / 2; i <= N; i++) {
    for (int j = 1; j <= M / 2; j++) {
      if((sq((int)i-42.0))+(sq((int)j-60.0)) <= sq((int)r) && exist == 1) data[i][j] = source_deg;
      else data[i][j] = 250.0;
    }
    for(int j = M / 2; j <= M; j++){
      if((sq((int)i-42.0))+(sq((int)j-60.0)) <= sq((int)r) && exist == 1) data[i][j] = source_deg;
      else data[i][j] = 200;
    }
  }
}

// SINGLE STEP : Calculate cell temperature by heat conduction & store data EXCEPT FOR BOUNDARIES
void step() {
	// CALCULATE
  for (int i = 1; i <= N; i++) {
    for (int j = 1; j <= M; j++) {
      if((sq((int)i-42.0)) + (sq((int)j-60.0)) <= sq((int)r) && exist == 1) dst[i][j] = source_deg;
      else dst[i][j] = src[i][j] + lambda * dt * (src[i-1][j] + src[i][j-1] + src[i+1][j] + src[i][j+1] - 4.0*src[i][j]) /dx /dx;
    }
  }
	// RETURN DATA
  for (int i = 1; i <= N; i++) { 
    for (int j = 1; j <= M; j++) {
      src[i][j] = dst[i][j];
    }
  }
}

// DRAW : Draw all cells
void DrawAllCell(float [][] data) {
  noStroke();

  // Draw boundaries
  for (int i = 1; i <= N; i++) {
    DrawCell(i, 0, data[i][0]);     // LEFT  WALL
    DrawCell(i, M+1, data[i][M+1]); // RIGHT WALL
  }
  for (int j = 1; j <= M; j++) {
    DrawCell(0, j, data[0][j]);     // UPPER WALL
    DrawCell(N+1, j, data[N+1][j]); // LOWER WALL
  }

	// Draw inner cells (not boundaries)
  for (int i = 1; i <= N; i++) {
    for (int j = 1; j <= M; j++) {
      DrawCell(i, j, data[i][j]);
    }
  }
}

// CONVERT INTO COLOR : Convert the value of variable t into another value with closed interval [0, 1.0]
color Temp2Color(float t) {
  color c;
  t += 1e-5;
  int val = int(( t % (1.0 / 6.0)) / (1.0 / 6.0) * 256.0);

	// COLOR VARIATIONS : 7 COLORS
  if(t < 0.0){
    c = color(255, 0, 255);        // purple
  } else if(t < 1.0 / 6.0){
    c = color(255 - val, 0, 255);  // purle to blue
  } else if(t < 2.0 / 6.0){
    c = color(0, val, 255);        // blue to lightblue
  } else if(t < 3.0 / 6.0){
    c = color(0, 255, 255 - val);  // lightblue to green
  } else if(t < 4.0 / 6.0){
    c = color(val, 255, 0);        // green to yellow
  } else if(t < 5.0 / 6.0){
    c = color(255, 255 - val, 0);  // yellow to red
  } else if(t < 6.0 / 6.0){
    c = color(255, val, val);      // red to white
  } else {
    c = color(255, 255, 255);      // white
  }

  return c;
}

// DRAW CELL : Draw a cell in row i and column j with temperature of temp
void DrawCell(int i, int j, float temp) {
  fill(Temp2Color(map(temp, 0, 300, 0, 1))); // convert into color by maping
  PVector v1 = TransCoord(new PVector(j, i));  // converting into (x, y)
  rect(v1.x, v1.y, mag, mag);                // draw
}

// CONVERT COORDINATE : Convert cell address(i, j) into coordinates(x, y)
PVector TransCoord(PVector p){
  p.mult(mag);
  p.add(XOrig, YOrig);
  return p;
}

// INV-CONVERT COORIDATE : Convert coordinates(x, y) into cell address(i, j)
PVector InvTransCoord(PVector p){
  p.sub(XOrig, YOrig);
  p.div(mag);
  return p;
}

// COLOR BAR : Display color bar from temperature
void DrawThermoBar(){
  for (int x = 0; x <= 300; x++) {
    color c = Temp2Color(map(x, 0, 300, 0, 1.0));
    stroke(c);
    line(x, 15, x, 25);

    if(x % 50 == 0){
      fill(255);
      textAlign(LEFT, TOP);
      text(str(x), x, 0);
    }
  }
}

// ======================================
// EVENT PROCESS
// ======================================

// EVENT 1 : FOR BOUNDARIES, largely change temperatures when they're clicked with mouse
void mouseClicked() {
  if (mouseButton == RIGHT) {
    // convert cursor position to cell address(i, j) and substitute v_1 
    PVector v1 = InvTransCoord(new PVector(mouseX, mouseY));
    float t;
    if (v1.x <= 1) {                   // LEFT
      t = 300.0 - src[1][0];
      for (int i = 1; i <= N; i++) {
        src[i][0] = t;
      }
    } else if (v1.x >= M) {            // RIGHT
      t = 300.0 - src[1][M+1];
      for (int i = 1; i <= N; i++) {
        src[i][M+1] = t;
      }
    } else if (v1.y <= 1) {            // UPPER
      t = 300.0 - src[0][1];
      for (int j = 1; j <= M; j++) {
        src[0][j] = t;
      }
    } else if (v1.y >= N) {            // LOWER
      t = 300.0 - src[N+1][1];
      for (int j = 1; j <= M; j++) {
        src[N+1][j] = t;
      }
    }
  }
}

// EVENT 2 : MAGNIFY SIMULATION SCREEN using mouse wheel
void mouseWheel(MouseEvent event){
  float e = event.getCount();
  mag = constrain(mag + e, 1, 10);
  XOrig = (width - ((int)mag*(M + 2))) / 2;
  YOrig = (height - 30 - (int)mag*(N + 2)) / 2 + 30;
}

// EVENT 3 : Heat/cool dragged/clicked cells by right mouse key at temperature of heating_deg [℃]
void mouseDragged() {
  if (mouseButton == LEFT) {
    PVector v1=InvTransCoord(new PVector(mouseX, mouseY));
    // convert into integer and limit with closed interval 1<=j<=M, 1<=i<=N
    int j = (int)constrain(v1.x, 1, M);
    int i = (int)constrain(v1.y, 1, N);
    src[i][j] = heating_deg;
  }
}

// EVENT 4 : MISCS SIMULATION CONTROL
void keyPressed(){
  if(key == 't'){
    heating_deg *= (-1);
    heating_mode = 1 - heating_mode;
  }
  // toggle heating/cooling
  else if(key == 'e'){
    exist = 1 - exist;
  }
  else if(key == 'r'){
    reset_s();
  }      // reset simulation
  else if(keyCode == UP){
    heating_deg += 10;
  }
  else if(keyCode == DOWN){
    heating_deg -= 10;
  }
  else if(keyCode == LEFT){
    source_deg += 10;
  } 
  else if(keyCode == RIGHT){
    source_deg -= 10;
  }
  
  if(key == '1'){
    r -= 1;
  }
  else if(key == '2'){
    r += 1;
  }
  
  
  if(heating_deg > 1000) heating_deg = 1000;
  else if(heating_deg < -1000) heating_deg = -1000;
  
  if(source_deg > 1000) source_deg = 1000;
  else if(source_deg < -1000) source_deg = -1000;
  
  if(r < 1) r = 1;
  else if(r > 40) r = 40;
}


// EVENT 5 : RESET SIMULATION
void reset_s(){
  heating_deg = 1000;
  heating_mode = 1;
  
  ref_ms = 0;
  m = 0;
  s = 0;
  ms = 0;
  start_ms = 0;
  
  source_deg = 200;
  r = 10;
  
  exist = 1;
  
  InitCell(src);
  InitCell(dst);
  start_ms = millis();
}

// EOF