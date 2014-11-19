package model.vo;
import flambe.math.Point;

/**
 * ...
 * @author mail@leobergman.se
 */
typedef InitResponseDataVO = {
	name:String,
	clientId:Int,
	clients:Array<Int>,
	positions:Array<Dynamic>
}