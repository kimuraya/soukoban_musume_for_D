module gamemain;

import std.math;
import std.stdio;
import std.string;
import std.windows.charset;
import DX_lib;
import convert;

//ゲームの状態
enum mode {
	TITLE,
	NEWGAME,
	CONTINUE,
	MOVEINPUT,
	STAGE_CLEAR,
	GAME_CLEAR,
};

//マップ上のオブジェクト
enum Object{
	OBJ_SPACE,
	OBJ_WALL,
	OBJ_GOAL,
	OBJ_BLOCK,
	OBJ_BLOCK_ON_GOAL,
	OBJ_MAN,
	OBJ_MAN_ON_GOAL,
	OBJ_UNKNOWN,
};

class GameMain {

	mode gameMode; //ゲームの状態を表す
	int[] key; // キーが押されているフレーム数を格納する
	const int stageHeight = 7; //マップの高さ
	const int stageWidth = 7; //マップの横幅
	Object[stageHeight][stageWidth] stageMap;
	const int stageTotalNumber = 5; //ゲームのステージの総数
	int currentStageNum = 1; //現在のステージ数

	//フォントの色とフォントの指定
	int fontType = 0;
	int white = 0;

	//ゲームのキャラクター
	int playerbuf = 0;
	int boxbuf = 0;
	int wallbuf = 0;
	int waybuf = 0;
	int goalbuf = 0;

	//コンストラクタ
	this() {
		//変数の初期化
		this.key = new int[256];
		this.gameMode = mode.TITLE; //ゲームモードをゲームの新規開始にする

		//フォントの色とフォントの指定（ゲームクリア時に使用）
		this.fontType = dx_CreateFontToHandle(null, 64, 5, -1);
		this.white = dx_GetColor(255, 255, 255);

		//画面のキャラクターを読み込む
		this.playerbuf = dx_LoadGraph(cast(char*)"gamedata\\player.png");
		this.boxbuf = dx_LoadGraph(cast(char*)"gamedata\\box.png");
		this.wallbuf = dx_LoadGraph(cast(char*)"gamedata\\wall.png");
		this.waybuf = dx_LoadGraph(cast(char*)"gamedata\\way.png");
		this.goalbuf = dx_LoadGraph(cast(char*)"gamedata\\goal.png");
	}

	//タイトル画面の作成と表示
	public void showTitle() {

		byte[] tmpKey = new byte[256]; // 現在のキーの入力状態を格納する

		string titleStr = format("倉庫番娘");
		titleStr = convertsMultibyteStringOfUtf(titleStr); //文字列をUTF-8からマルチバイト文字列に変換する
		dx_DrawStringToHandle(180, 100, cast(char*)toStringz(titleStr), white, fontType);

		//Enterキー入力待ちのメッセージ
		dx_DrawString(200, 300, cast(char*)toStringz("Please Press the Enter key"), white);

		dx_GetHitKeyStateAll(cast(byte*)tmpKey); // 全てのキーの入力状態を得る

		//Enterキーが押された場合
		if (tmpKey[KEY_INPUT_RETURN] == 1) {
			this.gameMode = mode.NEWGAME;
		}

		return;
	}

	//ゲームの開始準備
	public void gameInitialize() {

		//マップをファイルから読み込む

		this.mapInitialize("gamedata\\map1.txt");

		//ゲームの初期化処理が終わった為、ゲーム本編の画面に移動する
		gameMode = mode.MOVEINPUT;

		return;
	}

	//マップの読み込みと初期化
	private void mapInitialize(string fileName) {

		char[stageHeight][stageWidth] tempMap; //ファイルから読み込んだマップ

		//ファイルを読み込む
		auto fp = File(fileName, "r");

		for (int i= 0; i < stageHeight; i++) {

			char[] line;
			fp.readln(line);

			for (int j= 0; j < stageWidth; j++) {
				tempMap[i][j] = line[j];
			}
		}

		//ファイルから読み込んだマップをゲーム内部のマップに変換する
		for (int i= 0; i < stageHeight; i++) {

			for (int j= 0; j < stageWidth; j++) {

				switch(tempMap[i][j]) {
					case '#':
						stageMap[i][j] = Object.OBJ_WALL;
						break;
					case ' ':
						stageMap[i][j] = Object.OBJ_SPACE;
						break;
					case 'o':
						stageMap[i][j] = Object.OBJ_BLOCK;
						break;
					case 'O':
						stageMap[i][j] = Object.OBJ_BLOCK_ON_GOAL;
						break;
					case '.':
						stageMap[i][j] = Object.OBJ_GOAL;
						break;
					case 'p':
						stageMap[i][j] = Object.OBJ_MAN;
						break;
					case 'P':
						stageMap[i][j] = Object.OBJ_MAN_ON_GOAL;
						break;
					default:
						stageMap[i][j] = Object.OBJ_UNKNOWN;
						break;
				}
			}
		}

		return;
	}

	//ゲーム内部の計算フェーズ
	public void calc() {

		//ゲームのクリアチェック
		if (this.checkClear()) {
			//フラグを更新し、ゲームのクリア画面へ移動
			gameMode = mode.STAGE_CLEAR;
			return;
		}

		//入力取得
		this.updateKey();

		//Rキーが押された事を感知すると、マップを初期の状態に戻す
		this.mapReset();

		//ゲーム内部の更新処理
		this.upDate();

		return;
	}

	//ゲームのクリアチェック
	private bool checkClear() {
		//マップ上にブロックが無ければ、クリアしている
		for (int i = 0; i < stageHeight; i++) {
			for (int j= 0; j < stageWidth; j++) {
				if (stageMap[i][j] == Object.OBJ_BLOCK) {
					return false;
				}
			}
		}
		return true;
	}

	//キーの入力状態を更新する
	private int updateKey() {

		byte[] tmpKey = new byte[256]; //現在のキーの入力状態を格納する
		dx_GetHitKeyStateAll(cast(byte*)tmpKey); //全てのキーの入力状態を得る

		for (int i = 0; i < 256; i++) {

			if (tmpKey[i] != 0) { // i番のキーコードに対応するキーが押されていたら
				key[i]++; //加算
			} else { //押されていなければ
				key[i] = 0; //0にする
			}

		}

		return 0;
	}

	//マップをリセットする
	private void mapReset() {

		//Rキーが押された
		if (key[KEY_INPUT_R] == 1) {
			//マップをリセットする
			string fileName = format("gamedata\\map%d.txt", currentStageNum);
			this.mapInitialize(fileName);
		}

		return;
	}

	//ゲームのアップデート処理
	private void upDate() {

		//プレイヤーの座標
		int playerX = 0;
		int playerY = 0;

		//移動先差分
		int destinationDifferenceX = 0;
		int destinationDifferenceY = 0;

		//プレイヤーの座標を調べる
		for (int i = 0; i < stageHeight; i++) {
			for (int j= 0; j < stageWidth; j++) {
				if (stageMap[i][j] == Object.OBJ_MAN || stageMap[i][j] == Object.OBJ_MAN_ON_GOAL) {
					playerY = i;
					playerX = j;
					break;
				}
			}
		}

		//移動
		if (key[KEY_INPUT_UP] == 1) { //上キーが押された
			destinationDifferenceY = -1;
		}

		if (key[KEY_INPUT_DOWN] == 1) { //下キーが押された
			destinationDifferenceY = 1;
		}

		if (key[KEY_INPUT_RIGHT] == 1) { //右キーが押された
			destinationDifferenceX = 1;
		}

		if (key[KEY_INPUT_LEFT] == 1) { //左キーが押された
			destinationDifferenceX = -1;
		}

		//移動後の座標の変数
		int afterMovingX = playerX + destinationDifferenceX;
		int afterMovingY = playerY + destinationDifferenceY;

		//座標の最大最小チェック。外れていれば不許可
		if (afterMovingX >= stageWidth || afterMovingY >= stageHeight) {
			return;
		}

		//移動先が空白、またはゴールだった場合、人が移動する
		if (stageMap[afterMovingY][afterMovingX] == Object.OBJ_SPACE || stageMap[afterMovingY][afterMovingX] == Object.OBJ_GOAL) {
			
			//移動先がゴールなら、ゴール上の人になる
			if (stageMap[afterMovingY][afterMovingX] == Object.OBJ_GOAL) {
				stageMap[afterMovingY][afterMovingX] = Object.OBJ_MAN_ON_GOAL;
			} else {
				stageMap[afterMovingY][afterMovingX] = Object.OBJ_MAN;
			}

			//元々、ゴールの上にいたのなら、ゴール上の人は普通のゴールになる
			if (stageMap[playerY][playerX] == Object.OBJ_MAN_ON_GOAL) {
				stageMap[playerY][playerX] = Object.OBJ_GOAL;
			} else {
				stageMap[playerY][playerX] = Object.OBJ_SPACE;
			}

		//移動先が箱。移動先の次のマスが空白、またはゴールであれば移動する
		} else if (stageMap[afterMovingY][afterMovingX] == Object.OBJ_BLOCK || stageMap[afterMovingY][afterMovingX] == Object.OBJ_BLOCK_ON_GOAL) {

			//移動先の次のマスの座標
			int afterMovingX2 = afterMovingX + destinationDifferenceX;
			int afterMovingY2 = afterMovingY + destinationDifferenceY;

			//移動先の次がマップの範囲内かチェックする。範囲外であれば、押せない
			if (afterMovingX2 >= stageWidth || afterMovingY2 >= stageHeight) {
				return;
			}

			//移動先の次が空白、またはゴールである場合、マスを順次入れ替える
			if (stageMap[afterMovingY2][afterMovingX2] == Object.OBJ_SPACE || stageMap[afterMovingY2][afterMovingX2] == Object.OBJ_GOAL) {
				if (stageMap[afterMovingY2][afterMovingX2] == Object.OBJ_GOAL) {
					stageMap[afterMovingY2][afterMovingX2] = Object.OBJ_BLOCK_ON_GOAL;
				} else {
					stageMap[afterMovingY2][afterMovingX2] = Object.OBJ_BLOCK;
				}

				if (stageMap[afterMovingY][afterMovingX] == Object.OBJ_BLOCK_ON_GOAL) {
					stageMap[afterMovingY][afterMovingX] = Object.OBJ_MAN_ON_GOAL;
				} else {
					stageMap[afterMovingY][afterMovingX] = Object.OBJ_MAN;
				}

				if (stageMap[playerY][playerX] == Object.OBJ_MAN_ON_GOAL) {
					stageMap[playerY][playerX] = Object.OBJ_GOAL;
				} else {
					stageMap[playerY][playerX] = Object.OBJ_SPACE;
				}
			}
		}
	}

	//ゲーム画面の描画フェーズ
	public void draw() {

		//ゲームの説明等の表示
		string stageStr = format("STAGE %d", currentStageNum);
		stageStr = convertsMultibyteStringOfUtf(stageStr); //文字列をUTF-8からマルチバイト文字列に変換する
		dx_DrawString(460, 50, cast(char*)toStringz(stageStr), white);

		string messageStr = "Please input key";
		messageStr = convertsMultibyteStringOfUtf(messageStr); //文字列をUTF-8からマルチバイト文字列に変換する
		dx_DrawString(460, 80, cast(char*)toStringz(messageStr), white);

		string upStr = "　↑　";
		upStr = convertsMultibyteStringOfUtf(upStr); //文字列をUTF-8からマルチバイト文字列に変換する
		dx_DrawString(460, 100, cast(char*)toStringz(upStr), white);

		string rightLeftStr = "←　→";
		rightLeftStr = convertsMultibyteStringOfUtf(rightLeftStr); //文字列をUTF-8からマルチバイト文字列に変換する
		dx_DrawString(460, 120, cast(char*)toStringz(rightLeftStr), white);

		string downStr = "　↓　";
		downStr = convertsMultibyteStringOfUtf(downStr); //文字列をUTF-8からマルチバイト文字列に変換する
		dx_DrawString(460, 140, cast(char*)toStringz(downStr), white);

		string resetMessageStr = "リセット : R";
		resetMessageStr = convertsMultibyteStringOfUtf(resetMessageStr); //文字列をUTF-8からマルチバイト文字列に変換する
		dx_DrawString(460, 180, cast(char*)toStringz(resetMessageStr), white);

		//マップの配置通りにグラフィックを描画する
		for (int i= 0; i < stageHeight; i++) {

			for (int j= 0; j < stageWidth; j++) {
				switch(stageMap[i][j]) {
					case Object.OBJ_WALL:
						dx_DrawGraph(j * 50 + 60, i * 50 + 80, wallbuf, true);
						break;
					case Object.OBJ_SPACE:
						dx_DrawGraph(j * 50 + 60, i * 50 + 80, waybuf, true);
						break;
					case Object.OBJ_BLOCK:
						dx_DrawGraph(j * 50 + 60, i * 50 + 80, waybuf, true);
						dx_DrawGraph(j * 50 + 60, i * 50 + 80, boxbuf, true);
						break;
					case Object.OBJ_BLOCK_ON_GOAL:
						dx_DrawGraph(j * 50 + 60, i * 50 + 80, waybuf, true);
						dx_DrawGraph(j * 50 + 60, i * 50 + 80, boxbuf, true);
						break;
					case Object.OBJ_GOAL:
						dx_DrawGraph(j * 50 + 60, i * 50 + 80, goalbuf, true);
						break;
					case Object.OBJ_MAN:
						dx_DrawGraph(j * 50 + 60, i * 50 + 80, waybuf, true);
						dx_DrawGraph(j * 50 + 60, i * 50 + 80, playerbuf, true);
						break;
					case Object.OBJ_MAN_ON_GOAL:
						dx_DrawGraph(j * 50 + 60, i * 50 + 80, waybuf, true);
						dx_DrawGraph(j * 50 + 60, i * 50 + 80, playerbuf, true);
						break;
					case Object.OBJ_UNKNOWN:
						dx_DrawGraph(j * 50 + 60, i * 50 + 80, wallbuf, true);
						break;
					default:
						dx_DrawGraph(j * 50 + 60, i * 50 + 80, wallbuf, true);
						break;
				}
			}
		}

		return;
	}

	//ステージクリア画面の描画フェーズ
	public void stageClear() {

		//クリアしたステージが規定のステージ数を超えたら、ゲームはクリアした状態になる
		if (currentStageNum == stageTotalNumber) {
			this.gameMode = mode.GAME_CLEAR;
			return;
		}

		//クリアしたステージ数が規定の数に達しなければ、次のステージに進む
		if (currentStageNum < stageTotalNumber) {

			//ステージクリア画面の表示
			string stageStr = format(" ＳＴＡＧＥ");
			stageStr = convertsMultibyteStringOfUtf(stageStr); //文字列をUTF-8からマルチバイト文字列に変換する
			dx_DrawStringToHandle(29, 179, cast(char*)toStringz(stageStr), white, fontType);

			string clearStr = format("ＣＬＥＡＲ！！");
			clearStr = convertsMultibyteStringOfUtf(clearStr); //文字列をUTF-8からマルチバイト文字列に変換する
			dx_DrawStringToHandle(29, 229, cast(char*)toStringz(clearStr), white, fontType);

			//Enterキー入力待ちのメッセージ
			string enterMessageStr = format("Please Press the Enter key");
			enterMessageStr = convertsMultibyteStringOfUtf(enterMessageStr); //文字列をUTF-8からマルチバイト文字列に変換する
			dx_DrawString(150, 300, cast(char*)toStringz(enterMessageStr), white);

			//ここにEnterキーを押したら、次のステージのマップを生成し、新しいステージを始める処理を書く
			byte[] tmpKey = new byte[256]; // 現在のキーの入力状態を格納する
			dx_GetHitKeyStateAll(cast(byte*)tmpKey); // 全てのキーの入力状態を得る

			//Enterキーが押された場合
			if (tmpKey[KEY_INPUT_RETURN] == 1) {

				//現在のステージを更新
				this.currentStageNum++;

				//新しいマップを読み込む
				string fileName = format("gamedata\\map%d.txt", currentStageNum);

				//マップをファイルから読み込む
				this.mapInitialize(fileName);

				this.gameMode = mode.MOVEINPUT;
			}
		}

		return;
	}

	//ステージクリア画面の描画フェーズ
	public void gameClear() {

		//ゲームクリア画面の表示
		string gameStr = format("ＧＡＭＥ");
		gameStr = convertsMultibyteStringOfUtf(gameStr); //文字列をUTF-8からマルチバイト文字列に変換する
		dx_DrawStringToHandle(29, 179, cast(char*)toStringz(gameStr), white, fontType);

		string clearStr = format("ＣＬＥＡＲ！！");
		clearStr = convertsMultibyteStringOfUtf(clearStr); //文字列をUTF-8からマルチバイト文字列に変換する
		dx_DrawStringToHandle(29, 229, cast(char*)toStringz(clearStr), white, fontType);

		return;
	}
}