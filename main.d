import convert;
import DX_lib;
import gamemain;
import std.string;

void main()
{
	//ウィンドウ化
	dx_ChangeWindowMode(true);

	//ログの出力を停止する
	dx_SetOutApplicationLogValidFlag(false);

	//DXライブラリ初期化処理
	if(dx_DxLib_Init() == -1) {
		// エラーが起きたら直ちに終了
		return;
	}

	//描画先グラフィック領域の指定
	dx_SetDrawScreen(DX_SCREEN_BACK);

	//ウィンドウのタイトルを変更する
	string titleStr = "倉庫番娘";
	titleStr = convertsMultibyteStringOfUtf(titleStr); //文字列をUTF-8からマルチバイト文字列に変換する
	dx_SetMainWindowText(cast(char*)toStringz(titleStr));

	GameMain gameMain = new GameMain(); //ゲーム本体を作成

	// 裏画面を表画面に反映、ウインドウのメッセージを処理、画面を消す
	while (dx_ScreenFlip() == 0 && dx_ProcessMessage() == 0 && dx_ClearDrawScreen() == 0) {

		switch (gameMain.gameMode) {

			case mode.TITLE:
				gameMain.showTitle(); //タイトル画面の表示
				break;
			case mode.NEWGAME:
				gameMain.gameInitialize(); //ゲーム新規開始準備
				break;
			case mode.MOVEINPUT:
				gameMain.calc(); //ゲーム内部の計算フェーズ
				gameMain.draw(); //ゲーム画面の描画フェーズ
				break;
			case mode.STAGE_CLEAR:
				gameMain.draw(); //ゲーム画面の描画フェーズ
				gameMain.stageClear(); //ステージクリア画面の描画フェーズ
				break;
			case mode.GAME_CLEAR:
				gameMain.draw(); //ゲーム画面の描画フェーズ
				gameMain.gameClear(); //ゲームクリア画面の描画フェーズ
				break;
			default:
				gameMain.showTitle(); //タイトル画面の表示
				break;
		}
	}

	// ＤＸライブラリ使用の終了処理
	dx_DxLib_End();
}