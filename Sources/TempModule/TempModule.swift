import CommonUtility

public struct TempModule {
    public private(set) var text = "This is TempModule"

    public init() {
        print(text)
        
        CommonUtility.testRun()
    }
}
